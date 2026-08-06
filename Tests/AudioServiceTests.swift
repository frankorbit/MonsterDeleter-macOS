@preconcurrency import AVFoundation
import Foundation
import Testing
@testable import MonsterDeleter

@MainActor
struct AudioServiceTests {
  @Test
  func bundledAudioResourcesAreDecodable() throws {
    let resources = [
      (name: "bgm", extension: "mp3"),
      (name: "voice", extension: "mp4"),
      (name: "explosion", extension: "mp4"),
    ]

    for resource in resources {
      let url = try #require(
        Bundle.main.url(forResource: resource.name, withExtension: resource.extension)
      )
      let player = try AVAudioPlayer(contentsOf: url)
      #expect(player.prepareToPlay())
    }
  }

  @Test
  func missingResourcesDegradeToSilence() {
    _ = AudioService(bundle: Bundle(for: EmptyTestBundleMarker.self))
  }
}

private final class EmptyTestBundleMarker {}
