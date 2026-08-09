@preconcurrency import AppKit
import SwiftUI

struct SpriteSheetView: View {
  let animation: SpriteAnimation
  let displayHeight: CGFloat
  let onFramePresented: @MainActor (Int) -> Void
  let onCompletion: @MainActor () -> Void

  private let frames: [CGImage]

  init(
    animation: SpriteAnimation,
    displayHeight: CGFloat,
    frameProvider: SpriteSheetFrameProviding,
    onFramePresented: @escaping @MainActor (Int) -> Void = { _ in },
    onCompletion: @escaping @MainActor () -> Void = {}
  ) {
    self.animation = animation
    self.displayHeight = displayHeight
    self.onFramePresented = onFramePresented
    self.onCompletion = onCompletion
    frames = frameProvider.frames(for: animation.asset)
  }

  var body: some View {
    SpritePlaybackView(
      animation: animation,
      displayHeight: displayHeight,
      frames: frames,
      onFramePresented: onFramePresented,
      onCompletion: onCompletion
    )
    .id(animation.startedAt)
    .accessibilityHidden(true)
  }
}

private struct SpritePlaybackView: View {
  let animation: SpriteAnimation
  let displayHeight: CGFloat
  let frames: [CGImage]
  let onFramePresented: @MainActor (Int) -> Void
  let onCompletion: @MainActor () -> Void

  @State private var animationIndex = 0

  var body: some View {
    Group {
      if let frame = currentFrame {
        frameView(image: frame)
      } else {
        Color.clear
          .frame(width: frameSize.width, height: frameSize.height)
      }
    }
    .task(id: animationIndex) {
      await presentCurrentFrame()
    }
  }

  private var currentFrame: CGImage? {
    guard animation.frameIndices.indices.contains(animationIndex) else { return nil }

    let frameIndex = animation.frameIndices[animationIndex]
    guard frames.indices.contains(frameIndex) else { return nil }
    return frames[frameIndex]
  }

  private var frameSize: CGSize {
    animation.asset.displaySize(height: displayHeight)
  }

  @ViewBuilder
  private func frameView(image: CGImage) -> some View {
    Image(decorative: image, scale: 1)
      .resizable()
      .interpolation(.high)
      .frame(width: frameSize.width, height: frameSize.height)
      .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
      }
  }

  @MainActor
  private func presentCurrentFrame() async {
    guard animation.frameIndices.indices.contains(animationIndex),
          animation.framesPerSecond > 0
    else {
      onCompletion()
      return
    }

    onFramePresented(animationIndex)

    do {
      try await Task.sleep(for: .seconds(1 / animation.framesPerSecond))
    } catch {
      return
    }

    guard !Task.isCancelled else { return }

    if animationIndex == animation.frameIndices.count - 1 {
      if animation.loops {
        animationIndex = 0
      } else {
        onCompletion()
      }
    } else {
      animationIndex += 1
    }
  }
}
