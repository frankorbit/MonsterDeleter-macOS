@preconcurrency import AppKit
import FinderSync
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private enum InvocationMode {
    case interactive
    case finderService
  }

  private var landingWindowController: LandingWindowController?
  private var statusItem: NSStatusItem?
  private var statusItemMenu: NSMenu?
  private let overlayCoordinator = OverlayCoordinator()
  private let finderInvocationLocationTracker = FinderInvocationLocationTracker()
  private lazy var destructionServiceProvider = DestructionServiceProvider(
    invocationLocationProvider: { [weak self] in
      self?.finderInvocationLocationTracker.preferredLocation(fallback: NSEvent.mouseLocation)
        ?? NSEvent.mouseLocation
    }
  ) { [weak self] url, point in
    self?.presentTarget(url, initialScreenPoint: point, mode: .finderService)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    installMainMenu()
    installStatusItem()
    finderInvocationLocationTracker.start()
    registerFinderService()

    if let argumentURL = commandLineTargetURL() {
      presentTarget(argumentURL)
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    finderInvocationLocationTracker.stop()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard let route = urls.compactMap(AppRoute.init(url:)).first else { return }
    switch route {
    case let .trash(url, screenPoint):
      presentTarget(url, initialScreenPoint: screenPoint, mode: .finderService)
    }
  }

  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    presentTarget(URL(fileURLWithPath: filename))
    return true
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    showLandingWindow()
    return true
  }

  private func showLandingWindow() {
    guard !overlayCoordinator.isPresenting else { return }

    if landingWindowController == nil {
      let store = LandingStore(
        onStart: { [weak self] url in
          self?.presentTarget(url)
        },
        onOpenExtensionSettings: {
          FIFinderSyncController.showExtensionManagementInterface()
        }
      )
      landingWindowController = LandingWindowController(store: store)
    }

    landingWindowController?.showWindow(nil)
    landingWindowController?.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func presentTarget(
    _ url: URL,
    initialScreenPoint: CGPoint? = nil,
    mode: InvocationMode = .interactive
  ) {
    guard !overlayCoordinator.isPresenting else {
      NSSound.beep()
      return
    }

    do {
      try overlayCoordinator.present(
        url: url,
        initialScreenPoint: initialScreenPoint
      ) { [weak self] in
        self?.overlayDidFinish(mode: mode)
      }
      landingWindowController?.window?.orderOut(nil)
      NSApp.activate(ignoringOtherApps: true)
    } catch {
      let alert = NSAlert(error: error)
      alert.alertStyle = .warning
      alert.runModal()

      if mode == .interactive {
        showLandingWindow()
      }
    }
  }

  private func overlayDidFinish(mode: InvocationMode) {
    switch mode {
    case .finderService:
      break
    case .interactive:
      showLandingWindow()
    }
  }

  @objc
  private func handleStatusItemClick(_ sender: NSStatusBarButton) {
    if NSApp.currentEvent?.type == .rightMouseUp {
      statusItemMenu?.popUp(
        positioning: nil,
        at: NSPoint(x: 0, y: sender.bounds.minY),
        in: sender
      )
    } else {
      showLandingWindow()
    }
  }

  @objc
  private func showLandingWindowFromMenu() {
    showLandingWindow()
  }

  private func commandLineTargetURL() -> URL? {
    ProcessInfo.processInfo.arguments
      .dropFirst()
      .map(URL.init(fileURLWithPath:))
      .first(where: { FileManager.default.fileExists(atPath: $0.path) })
  }

  private func installMainMenu() {
    let mainMenu = NSMenu()
    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)

    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "退出大将怪兽摧毁",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    appMenuItem.submenu = appMenu
    NSApp.mainMenu = mainMenu
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    guard let button = item.button else { return }

    button.title = "🦖"
    button.toolTip = "打开大将怪兽摧毁"
    button.target = self
    button.action = #selector(handleStatusItemClick(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])

    let menu = NSMenu()
    let openItem = NSMenuItem(
      title: "打开大将怪兽摧毁",
      action: #selector(showLandingWindowFromMenu),
      keyEquivalent: ""
    )
    openItem.target = self
    menu.addItem(openItem)
    menu.addItem(.separator())

    let quitItem = NSMenuItem(
      title: "退出大将怪兽摧毁",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    quitItem.target = NSApp
    menu.addItem(quitItem)

    statusItemMenu = menu
    statusItem = item
  }

  private func registerFinderService() {
    NSApp.servicesProvider = destructionServiceProvider
    NSUpdateDynamicServices()
  }
}
