import CoreGraphics
import Foundation
import Testing
@testable import MonsterDeleter

@MainActor
struct MonsterDeleterStoreTests {
  @Test
  func leoMountAnimationSkipsClippedSourceFrames() {
    let animation = SpriteAnimation.leoMount()

    #expect(animation.frameIndices == [0, 1, 2, 3, 4, 10, 11, 12, 13, 14])
    #expect(animation.duration == 1.25)
  }

  @Test
  func walksOnscreenAtApproximatelyConstantSpeed() async throws {
    let audioService = MonsterDeleterStoreAudioServiceSpy()
    let targetPoint = CGPoint(x: 400, y: 300)
    let canvasSize = CGSize(width: 1_200, height: 800)
    let store = MonsterDeleterStore(
      target: DestructionTarget(
        url: URL(fileURLWithPath: "/tmp/monster-target.txt"),
        displayName: "monster-target.txt"
      ),
      trashService: MonsterDeleterStoreTrashServiceStub(),
      audioService: audioService,
      walkingDuration: 0.2,
      onFinished: {}
    )

    store.lockTarget(at: targetPoint, canvasSize: canvasSize)

    #expect(store.phase == .walking)
    #expect(store.monsterPosition.x == -store.monsterSize.width)
    #expect(audioService.backgroundMusicPlayCount == 1)

    store.monsterDidAppear()

    let initialX = -store.monsterSize.width
    let destinationX = targetPoint.x - store.monsterSize.width - 30
    #expect(store.monsterPosition.x == initialX)

    try await Task.sleep(for: .milliseconds(100))

    let traveledFraction = (store.monsterPosition.x - initialX) / (destinationX - initialX)
    #expect(traveledFraction > 0.3)
    #expect(traveledFraction < 0.75)
    store.cancel()
  }
}

private struct MonsterDeleterStoreTrashServiceStub: FileTrashServiceProtocol {
  func trash(_ url: URL) async throws {}
}

@MainActor
private final class MonsterDeleterStoreAudioServiceSpy: AudioServiceProtocol {
  private(set) var backgroundMusicPlayCount = 0

  func playBackgroundMusic() {
    backgroundMusicPlayCount += 1
  }

  func playVoice() {}
  func playExplosion() {}
  func stopAll() {}
}
