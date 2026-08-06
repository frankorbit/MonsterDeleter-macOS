import Foundation

struct DestructionTarget: Equatable, Sendable {
  let url: URL
  let displayName: String
}

enum TargetValidationError: LocalizedError, Equatable {
  case notAFileURL
  case doesNotExist
  case protectedLocation

  var errorDescription: String? {
    switch self {
    case .notAFileURL:
      "只能摧毁本机文件或文件夹。"
    case .doesNotExist:
      "目标已经不存在，可能刚刚被移动或删除了。"
    case .protectedLocation:
      "为了安全，不能选择磁盘根目录、用户主目录或系统关键目录本身。"
    }
  }
}
