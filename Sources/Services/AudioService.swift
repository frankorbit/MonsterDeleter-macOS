@preconcurrency import AVFoundation
import Foundation
import OSLog

@MainActor
protocol AudioServiceProtocol: AnyObject {
  func playBackgroundMusic()
  func playVoice()
  func playExplosion()
  func stopAll()
}

@MainActor
final class AudioService: AudioServiceProtocol {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.wuyi.MonsterDeleter",
    category: "AudioService"
  )

  private var backgroundPlayer: AVAudioPlayer?
  private var voicePlayer: AVAudioPlayer?
  private var explosionPlayer: AVAudioPlayer?

  init(bundle: Bundle = .main) {
    backgroundPlayer = makePlayer(named: "bgm", extension: "mp3", bundle: bundle)
    voicePlayer = makePlayer(named: "voice", extension: "mp4", bundle: bundle)
    explosionPlayer = makePlayer(named: "explosion", extension: "mp4", bundle: bundle)

    backgroundPlayer?.numberOfLoops = -1
    backgroundPlayer?.volume = 0.5
    voicePlayer?.volume = 1
    explosionPlayer?.volume = 0.35
  }

  func playBackgroundMusic() {
    backgroundPlayer?.currentTime = 0
    backgroundPlayer?.play()
  }

  func playVoice() {
    voicePlayer?.currentTime = 0
    voicePlayer?.play()
  }

  func playExplosion() {
    explosionPlayer?.currentTime = 0
    explosionPlayer?.play()
  }

  func stopAll() {
    backgroundPlayer?.stop()
    voicePlayer?.stop()
    explosionPlayer?.stop()
  }

  private func makePlayer(named name: String, extension fileExtension: String, bundle: Bundle) -> AVAudioPlayer? {
    let url = bundle.url(forResource: name, withExtension: fileExtension, subdirectory: "Audio")
      ?? bundle.url(forResource: name, withExtension: fileExtension)
    guard let url else {
      logger.error("找不到音频资源：\(name, privacy: .public).\(fileExtension, privacy: .public)")
      return nil
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      return player
    } catch {
      logger.error(
        "音频资源加载失败：\(url.lastPathComponent, privacy: .public)，\(error.localizedDescription, privacy: .public)"
      )
      return nil
    }
  }
}
