import Foundation

protocol TargetValidationServiceProtocol {
  func validate(_ url: URL) throws -> DestructionTarget
}

struct TargetValidationService: TargetValidationServiceProtocol {
  private let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func validate(_ url: URL) throws -> DestructionTarget {
    guard url.isFileURL else {
      throw TargetValidationError.notAFileURL
    }

    let standardizedURL = url.standardizedFileURL
    guard fileManager.fileExists(atPath: standardizedURL.path) else {
      throw TargetValidationError.doesNotExist
    }

    guard !protectedURLs.contains(standardizedURL) else {
      throw TargetValidationError.protectedLocation
    }

    let displayName = fileManager.displayName(atPath: standardizedURL.path)
    return DestructionTarget(url: standardizedURL, displayName: displayName)
  }

  private var protectedURLs: Set<URL> {
    let paths = [
      "/",
      "/System",
      "/Library",
      "/Applications",
      "/Users",
      "/Volumes",
      fileManager.homeDirectoryForCurrentUser.path,
      fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path,
    ]
    return Set(paths.map { URL(fileURLWithPath: $0).standardizedFileURL })
  }
}
