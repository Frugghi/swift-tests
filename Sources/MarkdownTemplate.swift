import Foundation

struct MarkdownTemplate: Template {

  let path: String

  init(path: String) {
    self.path = path
  }

  func replacement(for status: TestStatus) -> String {
    switch status {
      case .Success:   return ":arrow_right:"
      case .Failed:    return ":x:"
      case .NotTested: return ":heavy_minus_sign:"
      case .Unknown:   return ":grey_question:"
    }
  }

  func relativeURL(for name: String) -> String {
    return "#" + name.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "/", with: "")
  }

}
