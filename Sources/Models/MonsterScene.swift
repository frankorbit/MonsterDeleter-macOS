import CoreGraphics
import Foundation

enum MonsterScenePhase: Equatable, Sendable {
  case targeting
  case walking
  case pointing
  case awaitingConfirmation
  case kicking
  case celebrating
  case flying
  case failed
}

struct SpriteSheetAsset: Equatable, Sendable {
  let resourceName: String
  let columns: Int
  let rows: Int
  let sourceFrameSize: CGSize

  func displaySize(height: CGFloat) -> CGSize {
    CGSize(width: height * sourceFrameSize.width / sourceFrameSize.height, height: height)
  }

  static let walk = monster(named: "walk")
  static let point = monster(named: "point")
  static let kick = monster(named: "kick")
  static let leo = monster(named: "leo")
  static let fly = monster(named: "fly")
  static let explosion = SpriteSheetAsset(
    resourceName: "explosion",
    columns: 5,
    rows: 3,
    sourceFrameSize: CGSize(width: 1_440, height: 1_920)
  )

  private static func monster(named name: String) -> SpriteSheetAsset {
    SpriteSheetAsset(
      resourceName: name,
      columns: 5,
      rows: 3,
      sourceFrameSize: CGSize(width: 225, height: 400)
    )
  }
}

struct SpriteAnimation: Equatable, Sendable {
  let asset: SpriteSheetAsset
  let frameIndices: [Int]
  let framesPerSecond: Double
  let loops: Bool
  let startedAt: Date

  init(
    asset: SpriteSheetAsset,
    frameIndices: [Int] = Array(0..<15),
    framesPerSecond: Double = 8,
    loops: Bool,
    startedAt: Date = .now
  ) {
    self.asset = asset
    self.frameIndices = frameIndices
    self.framesPerSecond = framesPerSecond
    self.loops = loops
    self.startedAt = startedAt
  }

  var duration: TimeInterval {
    guard framesPerSecond > 0 else { return 0 }
    return Double(frameIndices.count) / framesPerSecond
  }

  static func leoMount(startedAt: Date = .now) -> SpriteAnimation {
    SpriteAnimation(
      asset: .leo,
      frameIndices: [0, 1, 2, 3, 4, 10, 11, 12, 13, 14],
      loops: false,
      startedAt: startedAt
    )
  }
}
