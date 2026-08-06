import CoreGraphics
import Foundation
import Testing
@testable import MonsterDeleter

@MainActor
struct FinderInvocationLocationTrackerTests {
  @Test
  func returnsRecentContextMenuLocation() {
    var uptime: TimeInterval = 100
    let tracker = FinderInvocationLocationTracker(
      maximumAge: 15,
      uptimeProvider: { uptime }
    )
    let rightClickLocation = CGPoint(x: 320, y: 480)

    tracker.record(location: rightClickLocation, timestamp: uptime)
    uptime += 8

    #expect(
      tracker.preferredLocation(fallback: CGPoint(x: 900, y: 120))
        == rightClickLocation
    )
  }

  @Test
  func rejectsStaleContextMenuLocation() {
    var uptime: TimeInterval = 100
    let tracker = FinderInvocationLocationTracker(
      maximumAge: 15,
      uptimeProvider: { uptime }
    )
    let fallback = CGPoint(x: 900, y: 120)

    tracker.record(location: CGPoint(x: 320, y: 480), timestamp: uptime)
    uptime += 16

    #expect(tracker.preferredLocation(fallback: fallback) == fallback)
  }
}
