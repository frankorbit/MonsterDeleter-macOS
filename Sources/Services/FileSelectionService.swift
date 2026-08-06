@preconcurrency import AppKit
import Foundation

@MainActor
protocol FileSelectionServiceProtocol {
  func chooseTarget() async -> URL?
}

@MainActor
struct FileSelectionService: FileSelectionServiceProtocol {
  func chooseTarget() async -> URL? {
    let panel = NSOpenPanel()
    panel.title = "选择要让怪兽摧毁的目标"
    panel.prompt = "选择"
    panel.message = "文件会在爆炸时移入废纸篓，之后仍然可以恢复。"
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.resolvesAliases = false

    return await withCheckedContinuation { continuation in
      panel.begin { response in
        continuation.resume(returning: response == .OK ? panel.url : nil)
      }
    }
  }
}
