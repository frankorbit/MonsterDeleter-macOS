import Testing
@testable import MonsterDeleter

@MainActor
struct SpriteSheetFrameCacheTests {
  @Test
  func cropsWalkSheetIntoDiscreteFrames() throws {
    let cache = SpriteSheetFrameCache()

    let frames = cache.frames(for: .walk)

    #expect(frames.count == 15)
    let firstFrame = try #require(frames.first)
    #expect(firstFrame.width == 225)
    #expect(firstFrame.height == 400)
  }

  @Test
  func reusesPreviouslyCroppedFrames() throws {
    let cache = SpriteSheetFrameCache()

    let firstLoad = cache.frames(for: .walk)
    let secondLoad = cache.frames(for: .walk)

    let firstFrame = try #require(firstLoad.first)
    let cachedFirstFrame = try #require(secondLoad.first)
    #expect(firstFrame === cachedFirstFrame)
  }
}
