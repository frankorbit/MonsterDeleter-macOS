import Foundation
import Observation

@Observable
@MainActor
final class LandingStore {
  private(set) var isChoosing = false

  private let fileSelectionService: FileSelectionServiceProtocol
  private let onStart: @MainActor (URL) -> Void
  private let onOpenExtensionSettings: @MainActor () -> Void

  init(
    fileSelectionService: FileSelectionServiceProtocol = FileSelectionService(),
    onStart: @escaping @MainActor (URL) -> Void,
    onOpenExtensionSettings: @escaping @MainActor () -> Void
  ) {
    self.fileSelectionService = fileSelectionService
    self.onStart = onStart
    self.onOpenExtensionSettings = onOpenExtensionSettings
  }

  func chooseTarget() {
    guard !isChoosing else { return }
    isChoosing = true

    Task { [weak self] in
      guard let self else { return }
      let url = await fileSelectionService.chooseTarget()
      isChoosing = false
      if let url {
        onStart(url)
      }
    }
  }

  func start(with url: URL) {
    onStart(url)
  }

  func openExtensionSettings() {
    onOpenExtensionSettings()
  }
}
