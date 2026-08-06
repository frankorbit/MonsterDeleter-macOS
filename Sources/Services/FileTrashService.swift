import Foundation

protocol FileTrashServiceProtocol: Sendable {
  func trash(_ url: URL) async throws
}

struct FileTrashService: FileTrashServiceProtocol {
  func trash(_ url: URL) async throws {
    try await Task.detached(priority: .userInitiated) {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }.value
  }
}
