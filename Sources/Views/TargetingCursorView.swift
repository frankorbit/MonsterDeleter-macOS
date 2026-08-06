@preconcurrency import AppKit
import SwiftUI

struct TargetingCursorView: NSViewRepresentable {
  func makeNSView(context: Context) -> CursorRegionNSView {
    CursorRegionNSView()
  }

  func updateNSView(_ nsView: CursorRegionNSView, context: Context) {
    nsView.window?.invalidateCursorRects(for: nsView)
  }
}

final class CursorRegionNSView: NSView {
  override func resetCursorRects() {
    super.resetCursorRects()
    addCursorRect(bounds, cursor: .monsterCrosshair)
  }
}

@MainActor
private extension NSCursor {
  static let monsterCrosshair: NSCursor = {
    let size = NSSize(width: 40, height: 40)
    let image = NSImage(size: size, flipped: false) { rect in
      NSColor.clear.setFill()
      rect.fill()

      let path = NSBezierPath()
      path.lineWidth = 2
      path.appendOval(in: NSRect(x: 8, y: 8, width: 24, height: 24))
      path.move(to: NSPoint(x: 20, y: 0))
      path.line(to: NSPoint(x: 20, y: 16))
      path.move(to: NSPoint(x: 20, y: 24))
      path.line(to: NSPoint(x: 20, y: 40))
      path.move(to: NSPoint(x: 0, y: 20))
      path.line(to: NSPoint(x: 16, y: 20))
      path.move(to: NSPoint(x: 24, y: 20))
      path.line(to: NSPoint(x: 40, y: 20))
      NSColor.systemRed.setStroke()
      path.stroke()
      return true
    }
    return NSCursor(image: image, hotSpot: NSPoint(x: 20, y: 20))
  }()
}
