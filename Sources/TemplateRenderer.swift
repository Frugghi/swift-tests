import Foundation
import POSIXRegex
import Tasks

class TemplateRenderer {

  private let template: Template

  private init(template: Template) {
    self.template = template
  }

  static func render(_ tests: [(test: Test, result: TestResult)], with template: Template) throws -> String {
    let renderer = TemplateRenderer(template: template)
    let contents = try String(contentsOfFile: template.path, encoding: .utf8)

    let kubectl = renderer.kubectlInfo()
    let curl = renderer.curlInfo()
    let replacements = [ "EMPTY_LINE": " ",
                         "TODAY_DATE": renderer.todayDate(),
                         "KUBECTL_VERSION": kubectl.version,
                         "KUBECTL_PLATFORM": kubectl.platform,
                         "CURL_VERSION": curl.version,
                         "CURL_PLATFORM": curl.platform,
                         "STATUS_SUCCESS": renderer.template.replacement(for: .Success),
                         "STATUS_FAILED": renderer.template.replacement(for: .Failed),
                         "STATUS_NOTTESTED": renderer.template.replacement(for: .NotTested),
                         "STATUS_UNKOWN": renderer.template.replacement(for: .Unknown) ]

    var output = ""
    var buffer: String?
    var groupLabels = false
    contents.characters.split { $0 == "\n" }.map(String.init).forEach {
      var line = $0
      if $0 == "BEGIN" || $0 == "BEGIN_GROUP" {
        buffer = ""
        groupLabels = $0 == "BEGIN_GROUP"
        return
      } else if let bufferLine = buffer, $0 == "END" {
        line = bufferLine
        buffer = nil
      } else if let bufferLine = buffer {
        if bufferLine == "" {
          buffer = "\($0)\n"
        } else {
          buffer = "\(bufferLine)\($0)\n"
        }
        return
      }

      let partialRenderedLine = renderer.apply(replacements, to: line)
      let renderedLine = renderer.apply(tests, to: partialRenderedLine, groupLabels: groupLabels)
      output += "\(renderedLine)"

      if !output.hasSuffix("\n") {
        output += "\n"
      }

      groupLabels = false
    }

    return output
  }

  private func apply(_ replacements: [String: String], to line: String) -> String {
    var line = line
    replacements.forEach { (key, value) in
      line = line.replacingOccurrences(of: key, with: value)
    }

    return "\(line)"
  }

  private func apply(_ tests: [(test: Test, result: TestResult)], to line: String, groupLabels: Bool) -> String {
    guard groupLabels else {
      return self.apply(tests, to: line)
    }

    var output = ""
    let testsLabels = tests.map { $0.0.label }
    for (index, label) in testsLabels.enumerated() where !testsLabels[0..<index].contains(label) {
      output += self.apply(tests.filter { $0.0.label == label }, to: line)
    }

    return output
  }

  private func apply(_ tests: [(test: Test, result: TestResult)], to templateLine: String) -> String {
    guard ["STATUS", "COMMAND", "CMD_LABEL", "REL_URL", "RAW_CMD", "EXPECTED", "NOTE", "RAW_OUTPUT", "RAW_ERROR", "EXIT_CODE"].filter({ templateLine.range(of: $0) != nil }).count > 0 else {
      return "\(templateLine)"
    }

    let firstLine = templateLine.replacingOccurrences(of: "HEADER\n", with: "").replacingOccurrences(of: "FOOTER\n", with: "")
    let headerRegex = try! Regex(pattern: "(HEADER\n.*HEADER[\n|$]|FOOTER\n.*FOOTER[\n|$])")
    let otherLines = headerRegex.groups(templateLine).reduce(templateLine) { $0.replacingOccurrences(of: $1, with: "") }
    var line = firstLine

    var output = ""
    tests.forEach {
      defer {
        if line == firstLine {
          line = otherLines
        }
      }

      guard ["RAW_OUTPUT", "RAW_ERROR", "EXIT_CODE"].filter({ line.range(of: $0) != nil }).count == 0 || $0.result.status == .Success || $0.result.status == .Failed else {
        return
      }

      let exitCode: String
      if let code = $0.result.exitCode {
        exitCode = "\(code)"
      } else {
        exitCode = "(no exit code)"
      }

      let asciiEscapeSequence = try! Regex(pattern: "\\[[0-9]+(;[0-9]+)?m")

      let rawOutput: String
      if let output = $0.result.output, output != "" {
        rawOutput = asciiEscapeSequence.replace(output, withTemplate: "")
      } else {
        rawOutput = "(no output)"
      }

      let rawError: String
      if let error = $0.result.error, error != "" {
        rawError = asciiEscapeSequence.replace(error, withTemplate: "")
      } else {
        rawError = "(no output)"
      }

      let replacements = [ "STATUS": self.template.replacement(for: $0.result.status),
                           "COMMAND": $0.test.name,
                           "CMD_LABEL": $0.test.label,
                           "RAW_CMD": $0.test.testedCommand,
                           "REL_URL": self.template.relativeURL(for: $0.test.name),
                           "REL_LABEL": self.template.relativeURL(for: $0.test.label),
                           "EXPECTED": $0.test.expectedResult ?? "",
                           "NOTES": $0.test.notes.joined(separator: "\n"),
                           "NOTE1": $0.test.notes.first ?? "",
                           "NOTE2": $0.test.notes.count >= 2 ? $0.test.notes[1] : "",
                           "EXIT_CODE": exitCode,
                           "RAW_OUTPUT": rawOutput,
                           "RAW_ERROR": rawError ]
      output += self.apply(replacements, to: line)

      if !output.hasSuffix("\n") {
        output += "\n"
      }
    }

    return output
  }

  private func kubectlInfo() -> (version: String, platform: String) {
    do {
      let result = try Task.run("kubectl", "version", "--client=true")
      let regex = try Regex(pattern: "GitVersion:\"([^\"]+)\".*Platform:\"([^\"]+)\"")
      let groups = regex.groups(result.stdoutStringUTF8)

      return (groups[0], groups[1])
    } catch {
      return ("ERROR", "\(error)")
    }
  }

  private func curlInfo() -> (version: String, platform: String) {
    do {
      let result = try Task.run("curl", "--version")
      let regex = try Regex(pattern: "curl\\s+([0-9]+\\.[0-9]+\\.[0-9]+)\\s+\\(([^\\)]+)\\)")
      let groups = regex.groups(result.stdoutStringUTF8)

      return (groups[0], groups[1])
    } catch {
      return ("ERROR", "\(error)")
    }
  }

  private func todayDate() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none

    return dateFormatter.string(from: Date())
  }

}
