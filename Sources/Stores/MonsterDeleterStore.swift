import CoreGraphics
import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class MonsterDeleterStore {
  private(set) var phase: MonsterScenePhase = .targeting
  private(set) var targetPoint = CGPoint.zero
  private(set) var monsterPosition = CGPoint.zero
  private(set) var monsterAnimation: SpriteAnimation?
  private(set) var explosionAnimation: SpriteAnimation?
  private(set) var errorMessage: String?
  private(set) var canvasSize = CGSize.zero

  let target: DestructionTarget

  private let trashService: FileTrashServiceProtocol
  private let audioService: AudioServiceProtocol
  private let onFinished: @MainActor () -> Void
  private let walkingDuration: TimeInterval
  private let flightDuration: TimeInterval
  private var sequenceTask: Task<Void, Never>?
  private var trashTask: Task<Void, Never>?
  private var kickAnimationFinished = false
  private var trashFinished = false

  private let monsterHeight: CGFloat = 250
  private let explosionHeight: CGFloat = 170
  private let kickImpactFrameIndex = 5

  init(
    target: DestructionTarget,
    trashService: FileTrashServiceProtocol = FileTrashService(),
    audioService: AudioServiceProtocol = AudioService(),
    walkingDuration: TimeInterval = 4.5,
    flightDuration: TimeInterval = 3.5,
    onFinished: @escaping @MainActor () -> Void
  ) {
    self.target = target
    self.trashService = trashService
    self.audioService = audioService
    self.walkingDuration = walkingDuration
    self.flightDuration = flightDuration
    self.onFinished = onFinished
  }

  var monsterSize: CGSize {
    SpriteSheetAsset.walk.displaySize(height: monsterHeight)
  }

  var explosionSize: CGSize {
    SpriteSheetAsset.explosion.displaySize(height: explosionHeight)
  }

  var showsConfirmation: Bool {
    phase == .awaitingConfirmation
  }

  var showsExplosion: Bool {
    explosionAnimation != nil
  }

  func lockTarget(at point: CGPoint, canvasSize: CGSize) {
    guard phase == .targeting else { return }

    self.canvasSize = canvasSize
    targetPoint = point
    phase = .walking
    monsterAnimation = SpriteAnimation(asset: .walk, loops: true)

    let maximumY = max(0, canvasSize.height - monsterSize.height)
    let y = min(max(0, point.y - monsterSize.height / 2 + 50), maximumY)
    monsterPosition = CGPoint(x: -monsterSize.width, y: y)
    audioService.playBackgroundMusic()
  }

  func monsterDidAppear() {
    guard phase == .walking, sequenceTask == nil else { return }

    let destinationX = max(8, targetPoint.x - monsterSize.width - 30)
    sequenceTask = Task { [weak self] in
      guard let self else { return }
      guard await walkMonster(to: destinationX) else { return }
      startPointing()
    }
  }

  func confirmDestruction() {
    guard phase == .awaitingConfirmation else { return }

    sequenceTask?.cancel()
    sequenceTask = nil
    kickAnimationFinished = false
    trashFinished = false
    phase = .kicking
    monsterAnimation = SpriteAnimation(asset: .kick, loops: false)
  }

  func monsterAnimationDidPresentFrame(
    _ animation: SpriteAnimation,
    animationIndex: Int
  ) {
    guard phase == .kicking,
          monsterAnimation == animation,
          animationIndex == kickImpactFrameIndex,
          explosionAnimation == nil
    else { return }

    startExplosion()
  }

  func monsterAnimationDidFinish(_ animation: SpriteAnimation) {
    guard monsterAnimation == animation else { return }

    switch phase {
    case .kicking:
      kickAnimationFinished = true
      startCelebratingIfReady()
    case .celebrating:
      startFlying()
    default:
      break
    }
  }

  func explosionAnimationDidPresentFrame(
    _ animation: SpriteAnimation,
    animationIndex: Int
  ) {
    guard explosionAnimation == animation,
          animationIndex == 0,
          trashTask == nil
    else { return }

    trashTask = Task { [weak self] in
      await self?.trashTarget()
    }
  }

  func explosionAnimationDidFinish(_ animation: SpriteAnimation) {
    guard explosionAnimation == animation else { return }
    explosionAnimation = nil
  }

  func cancel() {
    sequenceTask?.cancel()
    trashTask?.cancel()
    audioService.stopAll()
    onFinished()
  }

  private func startPointing() {
    phase = .pointing
    monsterAnimation = SpriteAnimation(
      asset: .point,
      frameIndices: [11, 12, 13, 14],
      loops: false
    )
    audioService.playVoice()

    sequenceTask = Task { [weak self] in
      guard let self, await pause(for: .milliseconds(500)) else { return }
      phase = .awaitingConfirmation
    }
  }

  private func startExplosion() {
    audioService.playExplosion()
    explosionAnimation = SpriteAnimation(asset: .explosion, loops: false)
  }

  private func trashTarget() async {
    do {
      try await trashService.trash(target.url)
      guard !Task.isCancelled else { return }
      trashFinished = true
      startCelebratingIfReady()
    } catch is CancellationError {
      return
    } catch {
      sequenceTask?.cancel()
      explosionAnimation = nil
      audioService.stopAll()
      errorMessage = error.localizedDescription
      phase = .failed
    }
  }

  private func startCelebratingIfReady() {
    guard phase == .kicking, kickAnimationFinished, trashFinished else { return }

    phase = .celebrating
    monsterAnimation = SpriteAnimation.leoMount()
  }

  private func startFlying() {
    guard phase == .celebrating else { return }

    phase = .flying
    monsterAnimation = SpriteAnimation(asset: .fly, loops: true)
    sequenceTask = Task { [weak self] in
      guard let self, await pause(for: .milliseconds(250)) else { return }

      let flightDestination = CGPoint(
        x: canvasSize.width + 200,
        y: monsterPosition.y
      )
      guard await moveMonster(to: flightDestination, duration: flightDuration) else { return }
      finish()
    }
  }

  private func finish() {
    audioService.stopAll()
    onFinished()
  }

  private func walkMonster(to destinationX: CGFloat) async -> Bool {
    await moveMonster(
      to: CGPoint(x: destinationX, y: monsterPosition.y),
      duration: walkingDuration
    )
  }

  private func moveMonster(to destination: CGPoint, duration: TimeInterval) async -> Bool {
    let initialPosition = monsterPosition
    guard duration > 0 else {
      monsterPosition = destination
      return true
    }

    let startedAt = ProcessInfo.processInfo.systemUptime
    while !Task.isCancelled {
      let elapsed = ProcessInfo.processInfo.systemUptime - startedAt
      let progress = min(1, elapsed / duration)
      monsterPosition = CGPoint(
        x: initialPosition.x + (destination.x - initialPosition.x) * progress,
        y: initialPosition.y + (destination.y - initialPosition.y) * progress
      )

      if progress >= 1 {
        return true
      }

      guard await pause(for: .milliseconds(16)) else { return false }
    }

    return false
  }

  private func pause(for duration: Duration) async -> Bool {
    do {
      try await Task.sleep(for: duration)
      return !Task.isCancelled
    } catch {
      return false
    }
  }
}
