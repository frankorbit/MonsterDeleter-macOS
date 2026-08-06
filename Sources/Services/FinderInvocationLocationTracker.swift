@preconcurrency import AppKit
import Foundation

@MainActor
final class FinderInvocationLocationTracker {
  private struct Sample {
    let location: CGPoint
    let timestamp: TimeInterval
  }

  private let maximumAge: TimeInterval
  private let uptimeProvider: @MainActor () -> TimeInterval
  private var globalMonitor: Any?
  private var latestSample: Sample?

  init(
    maximumAge: TimeInterval = 15,
    uptimeProvider: @escaping @MainActor () -> TimeInterval = {
      ProcessInfo.processInfo.systemUptime
    }
  ) {
    self.maximumAge = maximumAge
    self.uptimeProvider = uptimeProvider
  }

  func start() {
    guard globalMonitor == nil else { return }

    globalMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.rightMouseDown, .leftMouseDown]
    ) { [weak self] event in
      let isContextMenuClick = event.type == .rightMouseDown
        || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
      guard isContextMenuClick else { return }

      let location = event.locationInWindow
      let timestamp = event.timestamp
      Task { @MainActor [weak self] in
        self?.record(location: location, timestamp: timestamp)
      }
    }
  }

  func stop() {
    guard let globalMonitor else { return }
    NSEvent.removeMonitor(globalMonitor)
    self.globalMonitor = nil
  }

  func preferredLocation(fallback: CGPoint) -> CGPoint {
    guard let latestSample else { return fallback }

    let age = uptimeProvider() - latestSample.timestamp
    guard age >= 0, age <= maximumAge else { return fallback }
    return latestSample.location
  }

  func record(location: CGPoint, timestamp: TimeInterval) {
    latestSample = Sample(location: location, timestamp: timestamp)
  }
}
