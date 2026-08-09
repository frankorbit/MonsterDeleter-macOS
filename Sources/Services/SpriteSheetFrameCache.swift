import CoreGraphics
import Foundation
import ImageIO

@MainActor
protocol SpriteSheetFrameProviding: AnyObject {
  func frames(for asset: SpriteSheetAsset) -> [CGImage]
  func prepare(_ assets: [SpriteSheetAsset]) async
}

@MainActor
final class SpriteSheetFrameCache: SpriteSheetFrameProviding {
  private let bundle: Bundle
  private var cachedFrames: [String: [CGImage]] = [:]
  private var preparationTasks: [String: Task<PreparedSpriteFrames, Never>] = [:]

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  func frames(for asset: SpriteSheetAsset) -> [CGImage] {
    let cacheKey = cacheKey(for: asset)
    if let frames = cachedFrames[cacheKey] {
      return frames
    }

    let frames = resourceURL(for: asset)
      .map { loadSpriteFrames(from: $0, asset: asset).frames }
      ?? []
    cachedFrames[cacheKey] = frames
    return frames
  }

  func prepare(_ assets: [SpriteSheetAsset]) async {
    for asset in assets {
      await prepare(asset)
    }
  }

  private func prepare(_ asset: SpriteSheetAsset) async {
    let cacheKey = cacheKey(for: asset)
    guard cachedFrames[cacheKey] == nil else { return }

    let preparationTask: Task<PreparedSpriteFrames, Never>
    if let existingTask = preparationTasks[cacheKey] {
      preparationTask = existingTask
    } else if let url = resourceURL(for: asset) {
      let newTask = Task.detached(priority: .userInitiated) {
        loadSpriteFrames(from: url, asset: asset)
      }
      preparationTasks[cacheKey] = newTask
      preparationTask = newTask
    } else {
      cachedFrames[cacheKey] = []
      return
    }

    let preparedFrames = await preparationTask.value
    cachedFrames[cacheKey] = preparedFrames.frames
    preparationTasks[cacheKey] = nil
  }

  private func cacheKey(for asset: SpriteSheetAsset) -> String {
    "\(asset.resourceName)-\(asset.columns)x\(asset.rows)"
  }

  private func resourceURL(for asset: SpriteSheetAsset) -> URL? {
    bundle.url(
      forResource: asset.resourceName,
      withExtension: "png",
      subdirectory: "Images"
    ) ?? bundle.url(forResource: asset.resourceName, withExtension: "png")
  }
}

private struct PreparedSpriteFrames: @unchecked Sendable {
  let frames: [CGImage]
}

private func loadSpriteFrames(
  from url: URL,
  asset: SpriteSheetAsset
) -> PreparedSpriteFrames {
  let imageOptions = [
    kCGImageSourceShouldCache: true,
    kCGImageSourceShouldCacheImmediately: true,
  ] as CFDictionary

  guard asset.columns > 0,
        asset.rows > 0,
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
        let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, imageOptions),
        sourceImage.width.isMultiple(of: asset.columns),
        sourceImage.height.isMultiple(of: asset.rows)
  else {
    return PreparedSpriteFrames(frames: [])
  }

  let frameWidth = sourceImage.width / asset.columns
  let frameHeight = sourceImage.height / asset.rows

  let frames = (0..<(asset.columns * asset.rows)).compactMap { frameIndex in
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

  return PreparedSpriteFrames(frames: frames)
}
