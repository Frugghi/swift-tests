import Tasks

enum TestStatus {
  case Success, Failed, NotTested, Unknown
}

struct TestResult {
  let status: TestStatus
  let exitCode: Int?
  let output: String?
  let error: String?

  init(status: TestStatus, exitCode: Int? = nil, output: String? = nil, error: String? = nil) {
    self.status = status
    self.exitCode = exitCode
    self.output = output
    self.error = error
  }

}

class Test: CustomStringConvertible {
  let label: String
  let name: String

  private let command: [String]
  private var status: ((Int32, String, String) -> (TestStatus))?

  private(set) var notes: [String] = []
  private(set) var prerequisites: [String] = []
  private(set) var postrequisites: [String] = []
  private(set) var skip = false
  private(set) var expectedResult: String?

  var testedCommand: String {
    return self.command.joined(separator: " ")
  }

  var description: String {
    return "\(self.name) (label: \(self.label))"
  }

  convenience init(label: String, name: String? = nil, expected: String? = nil, command: String...) {
    self.init(label: label, name: name, expected: expected, command: command)
  }

  init(label: String, name: String? = nil, expected: String? = nil, command: [String]) {
    self.label = label
    self.name = name ?? label
    self.expectedResult = expected
    self.command = command
  }

  @discardableResult
  func status(_ status: @escaping (Int32, String, String) -> (TestStatus)) -> Self {
    self.status = status
    return self
  }

  @discardableResult
  func supportedIf(exitCode: Int32) -> Self {
    return self.status {
      return $0.0 == exitCode ? .Success : .Failed
    }
  }

  @discardableResult
  func supportedIf(_ expected: ExpectedResult) -> Self {
    return self.status {
      return expected.test(exitCode: $0.0, stdOut: $0.1, stdErr: $0.2) ? .Success : .Failed
    }
  }

  @discardableResult
  func markDeprecated() -> Self {
    return self.addNote("Deprecated")
  }

  @discardableResult
  func markMissing() -> Self {
    return self.addNote("Missing test")
  }

  @discardableResult
  func markDoNotRun() -> Self {
    self.skip = true
    return self
  }

  @discardableResult
  func addNote(_ note: String) -> Self {
    self.notes.append(note)
    return self
  }

  @discardableResult
  func addNotes(_ notes: [String]) -> Self {
    self.notes += notes
    return self
  }

  @discardableResult
  func pre(_ prerequisite: String) -> Self {
    return self.pre([prerequisite])
  }

  @discardableResult
  func pre(_ prerequisites: [String]) -> Self {
    self.prerequisites += prerequisites
    return self
  }

  @discardableResult
  func post(_ postrequisite: String) -> Self {
    return self.post([postrequisite])
  }

  @discardableResult
  func post(_ postrequisites: [String]) -> Self {
    self.postrequisites += postrequisites
    return self
  }

  func run() -> TestResult {
    guard let getStatus = self.status else {
      self.markMissing()
      return TestResult(status: .Unknown)
    }

    let testResult: TestResult

    self.run(self.prerequisites)

    do {
      let result = try Task.run(self.command)
      let testStatus = getStatus(result.code, result.stdoutStringUTF8, result.stderrStringUTF8)

      if testStatus == .Failed {
        print("Failed:\n - Out: \(result.stdoutStringUTF8)\n - Err: \(result.stderrStringUTF8)")
      }

      testResult = TestResult(status: testStatus, exitCode: Int(result.code), output: result.stdoutStringUTF8, error: result.stderrStringUTF8)
    } catch {
      print("Task failed with \(error)")
      testResult = TestResult(status: .Unknown)
    }

    self.run(self.postrequisites)

    return testResult
  }

  private func run(_ commands: [String]) {
    commands.forEach {
      let command = $0.characters.split(separator: " ").map(String.init)

      do {
        _ = try Task.run(command)
      } catch {}
    }
  }

}
