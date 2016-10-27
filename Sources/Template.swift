
protocol Template {

  var path: String { get }

  func replacement(for status: TestStatus) -> String
  func relativeURL(for name: String) -> String

}
