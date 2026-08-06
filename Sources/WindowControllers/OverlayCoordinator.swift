@preconcurrency import AppKit
import Foundation

@MainActor
final class OverlayCoordinator {
  private let validationService: TargetValidationServiceProtocol
  private var windowController: OverlayWindowController?

  init(validationService: TargetValidationServiceProtocol = TargetValidationService()) {
    self.validationService = validationService
  }

  var isPresenting: Bool {
    windowController != nil
  }

  func present(
    url: URL,
    initialScreenPoint: CGPoint? = nil,
    onFinished: @escaping @MainActor () -> Void
  ) throws {
    guard windowController == nil else { return }

    let target = try validationService.validate(url)
    let targetScreenPoint = initialScreenPoint ?? NSEvent.mouseLocation
    let screen = NSScreen.screens.first(where: { $0.frame.contains(targetScreenPoint) })
      ?? NSScreen.main
      ?? NSScreen.screens[0]
    let controller = OverlayWindowController(
      target: target,
      screen: screen,
      initialScreenPoint: initialScreenPoint
    ) { [weak self] in
      guard let self else { return }
      windowController?.close()
      windowController = nil
      onFinished()
    }
    windowController = controller
    controller.showWindow(nil)
  }

  func cancel() {
    windowController?.close()
    windowController = nil
  }
}
