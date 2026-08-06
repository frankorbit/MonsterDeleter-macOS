@preconcurrency import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController: NSWindowController {
  private let store: MonsterDeleterStore
  private let initialTargetPoint: CGPoint?
  private let canvasSize: CGSize

  init(
    target: DestructionTarget,
    screen: NSScreen,
    initialScreenPoint: CGPoint? = nil,
    onFinished: @escaping @MainActor () -> Void
  ) {
    let panel = EscapeHandlingPanel(
      contentRect: screen.frame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.level = .screenSaver
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.isReleasedWhenClosed = false

    let store = MonsterDeleterStore(target: target) { [weak panel] in
      panel?.orderOut(nil)
      onFinished()
    }

    self.store = store
    self.canvasSize = screen.frame.size
    self.initialTargetPoint = initialScreenPoint.map { point in
      CGPoint(
        x: min(max(0, point.x - screen.frame.minX), screen.frame.width),
        y: min(max(0, screen.frame.maxY - point.y), screen.frame.height)
      )
    }

    panel.onEscape = { [weak store] in
      store?.cancel()
    }
    panel.contentView = NSHostingView(rootView: TargetingOverlayView(store: store))

    super.init(window: panel)
  }

  override func showWindow(_ sender: Any?) {
    super.showWindow(sender)
    window?.makeKeyAndOrderFront(sender)

    if let initialTargetPoint {
      store.lockTarget(at: initialTargetPoint, canvasSize: canvasSize)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("不支持通过 NSCoder 创建窗口。")
  }
}

private final class EscapeHandlingPanel: NSPanel {
  var onEscape: (() -> Void)?

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 {
      onEscape?()
    } else {
      super.keyDown(with: event)
    }
  }
}
