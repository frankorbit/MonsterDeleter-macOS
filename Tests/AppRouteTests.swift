import Foundation
import Testing
@testable import MonsterDeleter

struct AppRouteTests {
  @Test
  func parsesEncodedFilePath() throws {
    var components = URLComponents()
    components.scheme = "monsterdeleter"
    components.host = "trash"
    components.queryItems = [URLQueryItem(name: "path", value: "/tmp/怪兽 文件.txt")]

    let url = try #require(components.url)
    #expect(
      AppRoute(url: url) == .trash(
        URL(fileURLWithPath: "/tmp/怪兽 文件.txt"),
        screenPoint: nil
      )
    )
  }

  @Test
  func parsesFinderScreenPoint() throws {
    var components = URLComponents()
    components.scheme = "monsterdeleter"
    components.host = "trash"
    components.queryItems = [
      URLQueryItem(name: "path", value: "/tmp/monster.txt"),
      URLQueryItem(name: "x", value: "321.5"),
      URLQueryItem(name: "y", value: "654.25"),
    ]

    let url = try #require(components.url)
    #expect(
      AppRoute(url: url) == .trash(
        URL(fileURLWithPath: "/tmp/monster.txt"),
        screenPoint: CGPoint(x: 321.5, y: 654.25)
      )
    )
  }

  @Test
  func rejectsUnknownRoute() {
    #expect(AppRoute(url: URL(string: "monsterdeleter://unknown")!) == nil)
  }
}
