@preconcurrency import AppKit
import CoreGraphics
import Foundation

@MainActor
protocol SpriteSheetFrameProviding: AnyObject {
  func frames(for asset: SpriteSheetAsset) -> [CGImage]
}

@MainActor
final class SpriteSheetFrameCache: SpriteSheetFrameProviding {
  private let bundle: Bundle
  private var cachedFrames: [String: [CGImage]] = [:]

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  func frames(for asset: SpriteSheetAsset) -> [CGImage] {
    let cacheKey = "\(asset.resourceName)-\(asset.columns)x\(asset.rows)"
    if let frames = cachedFrames[cacheKey] {
      return frames
    }

    let frames = loadFrames(for: asset)
    cachedFrames[cacheKey] = frames
    return frames
  }

  private func loadFrames(for asset: SpriteSheetAsset) -> [CGImage] {
    guard asset.columns > 0,
          asset.rows > 0,
          let url = bundle.url(
            forResource: asset.resourceName,
            withExtension: "png",
            subdirectory: "Images"
          ) ?? bundle.url(forResource: asset.resourceName, withExtension: "png"),
          let image = NSImage(contentsOf: url),
          let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          sourceImage.width.isMultiple(of: asset.columns),
          sourceImage.height.isMultiple(of: asset.rows)
    else {
      return []
    }

    let frameWidth = sourceImage.width / asset.columns
    let frameHeight = sourceImage.height / asset.rows

    return (0..<(asset.columns * asset.rows)).compactMap { frameIndex in
      let column = frameIndex % asset.columns
      let row = frameIndex / asset.columns
      let cropRect = CGRect(
        x: column * frameWidth,
        y: row * frameHeight,
        width: frameWidth,
        height: frameHeight
      )
      return sourceImage.cropping(to: cropRect)
    }
  }
}
