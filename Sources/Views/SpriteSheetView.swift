@preconcurrency import AppKit
import SwiftUI

struct SpriteSheetView: View {
  let animation: SpriteAnimation
  let displayHeight: CGFloat

  private let frames: [CGImage]

  init(
    animation: SpriteAnimation,
    displayHeight: CGFloat,
    frameProvider: SpriteSheetFrameProviding
  ) {
    self.animation = animation
    self.displayHeight = displayHeight
    frames = frameProvider.frames(for: animation.asset)
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / animation.framesPerSecond)) { context in
      let frameIndex = frameIndex(at: context.date)
      if frames.indices.contains(frameIndex) {
        frameView(image: frames[frameIndex])
      }
    }
    .accessibilityHidden(true)
  }

  private func frameIndex(at date: Date) -> Int {
    guard !animation.frameIndices.isEmpty else { return 0 }

    let elapsed = max(0, date.timeIntervalSince(animation.startedAt))
    let rawIndex = Int(elapsed * animation.framesPerSecond)
    let animationIndex = animation.loops
      ? rawIndex % animation.frameIndices.count
      : min(rawIndex, animation.frameIndices.count - 1)
    return animation.frameIndices[animationIndex]
  }

  @ViewBuilder
  private func frameView(image: CGImage) -> some View {
    let frameSize = animation.asset.displaySize(height: displayHeight)

    Image(decorative: image, scale: 1)
      .resizable()
      .interpolation(.high)
      .frame(width: frameSize.width, height: frameSize.height)
      .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
      }
  }
}
