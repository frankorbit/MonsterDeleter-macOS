@preconcurrency import AppKit
import Foundation
import Testing
@testable import MonsterDeleter

@MainActor
struct DestructionServiceProviderTests {
  @Test
  func routesSingleFinderURL() {
    let target = URL(fileURLWithPath: "/tmp/monster-target.txt")
    let mouseLocation = CGPoint(x: 240, y: 360)
    var receivedURL: URL?
    var receivedPoint: CGPoint?
    let provider = DestructionServiceProvider(
      invocationLocationProvider: { mouseLocation }
    ) { url, point in
      receivedURL = url
      receivedPoint = point
    }
    let pasteboard = NSPasteboard(name: .init("MonsterDeleterTests.SingleURL"))
    pasteboard.clearContents()
    #expect(pasteboard.writeObjects([target as NSURL]))

    var serviceError: NSString?
    provider.summonMonster(pasteboard, userData: nil, error: &serviceError)

    #expect(serviceError == nil)
    #expect(receivedURL == target)
    #expect(receivedPoint == mouseLocation)
  }

  @Test
  func rejectsMultipleFinderURLs() {
    let provider = DestructionServiceProvider { _, _ in
      Issue.record("多选目标不应启动怪兽流程。")
    }
    let pasteboard = NSPasteboard(name: .init("MonsterDeleterTests.MultipleURLs"))
    pasteboard.clearContents()
    let urls = [
      URL(fileURLWithPath: "/tmp/monster-one.txt") as NSURL,
      URL(fileURLWithPath: "/tmp/monster-two.txt") as NSURL,
    ]
    #expect(pasteboard.writeObjects(urls))

    var serviceError: NSString?
    provider.summonMonster(pasteboard, userData: nil, error: &serviceError)

    #expect(serviceError != nil)
  }

  @Test
  func advertisesFinderServiceInInfoPlist() throws {
    let services = try #require(Bundle.main.object(forInfoDictionaryKey: "NSServices") as? [[String: Any]])
    let service = try #require(services.first)

    #expect(service["NSMessage"] as? String == "summonMonster")
    #expect(service["NSSendFileTypes"] as? [String] == ["public.item"])
  }

  @Test
  func runsAsMenuBarAgentWithoutDockIcon() {
    #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
  }
}
