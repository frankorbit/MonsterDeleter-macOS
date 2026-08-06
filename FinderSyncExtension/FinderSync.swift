@preconcurrency import AppKit
import FinderSync

@MainActor
final class FinderSync: FIFinderSync {
  override init() {
    super.init()
    // Finder Sync 只会为受监控目录提供菜单；根目录覆盖本机和已挂载卷。
    FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
  }

  override func menu(for menuKind: FIMenuKind) -> NSMenu? {
    guard menuKind == .contextualMenuForItems,
          FIFinderSyncController.default().selectedItemURLs()?.count == 1
    else {
      return nil
    }

    let menu = NSMenu(title: "大将怪兽摧毁")
    let item = NSMenuItem(
      title: "召唤大将怪兽摧毁",
      action: #selector(summonMonster(_:)),
      keyEquivalent: ""
    )
    item.representedObject = NSValue(point: NSEvent.mouseLocation)
    item.target = self
    menu.addItem(item)
    return menu
  }

  @objc
  private func summonMonster(_ sender: NSMenuItem) {
    guard let target = FIFinderSyncController.default().selectedItemURLs()?.first else { return }
    let invocationLocation = (sender.representedObject as? NSValue)?.pointValue
      ?? NSEvent.mouseLocation

    var components = URLComponents()
    components.scheme = "monsterdeleter"
    components.host = "trash"
    components.queryItems = [
      URLQueryItem(name: "path", value: target.path),
      URLQueryItem(name: "x", value: String(Double(invocationLocation.x))),
      URLQueryItem(name: "y", value: String(Double(invocationLocation.y))),
    ]
    guard let commandURL = components.url else { return }

    NSWorkspace.shared.open(commandURL)
  }
}
