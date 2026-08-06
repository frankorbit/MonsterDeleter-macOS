@preconcurrency import AppKit
import Foundation

@MainActor
final class DestructionServiceProvider: NSObject {
  private let invocationLocationProvider: @MainActor () -> CGPoint
  private let onRequest: @MainActor (URL, CGPoint) -> Void

  init(
    invocationLocationProvider: @escaping @MainActor () -> CGPoint = { NSEvent.mouseLocation },
    onRequest: @escaping @MainActor (URL, CGPoint) -> Void
  ) {
    self.invocationLocationProvider = invocationLocationProvider
    self.onRequest = onRequest
  }

  @objc
  func summonMonster(
    _ pasteboard: NSPasteboard,
    userData: String?,
    error: AutoreleasingUnsafeMutablePointer<NSString?>
  ) {
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true,
    ]
    let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: options) ?? []
    let urls = objects.compactMap { ($0 as? NSURL).map { $0 as URL } }

    guard urls.count == 1, let target = urls.first else {
      error.pointee = "请在 Finder 中只选择一个文件或文件夹。"
      return
    }

    onRequest(target, invocationLocationProvider())
  }
}
