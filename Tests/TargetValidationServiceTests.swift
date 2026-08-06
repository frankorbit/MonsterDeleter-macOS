import Foundation
import Testing
@testable import MonsterDeleter

struct TargetValidationServiceTests {
  @Test
  func acceptsExistingFile() throws {
    let fileManager = FileManager.default
    let directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: directory) }

    let file = directory.appendingPathComponent("target.txt")
    try Data("hello".utf8).write(to: file)

    let target = try TargetValidationService(fileManager: fileManager).validate(file)
    #expect(target.url == file.standardizedFileURL)
    #expect(target.displayName == "target.txt")
  }

  @Test
  func rejectsMissingTarget() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    #expect(throws: TargetValidationError.doesNotExist) {
      try TargetValidationService().validate(url)
    }
  }

  @Test
  func rejectsRootDirectory() {
    #expect(throws: TargetValidationError.protectedLocation) {
      try TargetValidationService().validate(URL(fileURLWithPath: "/"))
    }
  }
}
