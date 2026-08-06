import CoreGraphics
import Foundation

enum AppRoute: Equatable, Sendable {
  case trash(URL, screenPoint: CGPoint?)

  init?(url: URL) {
    guard url.scheme?.lowercased() == "monsterdeleter",
          url.host?.lowercased() == "trash",
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let path = components.queryItems?.first(where: { $0.name == "path" })?.value,
          !path.isEmpty
    else {
      return nil
    }

    let x = components.queryItems?.first(where: { $0.name == "x" })?.value.flatMap(Double.init)
    let y = components.queryItems?.first(where: { $0.name == "y" })?.value.flatMap(Double.init)
    let screenPoint: CGPoint? = if let x, let y {
      CGPoint(x: x, y: y)
    } else {
      nil
    }

    self = .trash(URL(fileURLWithPath: path), screenPoint: screenPoint)
  }
}
