@preconcurrency import AppKit
import SwiftUI

@MainActor
final class LandingWindowController: NSWindowController {
  init(store: LandingStore) {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "大将怪兽摧毁"
    window.center()
    window.isReleasedWhenClosed = false
    window.contentViewController = NSHostingController(rootView: LandingView(store: store))
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("不支持通过 NSCoder 创建窗口。")
  }
}
