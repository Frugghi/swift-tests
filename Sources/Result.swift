import POSIXRegex

protocol ExpectedResult {

  init?(_ expected: String)
  func test(exitCode: Int32, stdOut: String, stdErr: String) -> Bool

}

struct ExitCodeResult: ExpectedResult {

  let exitCode: Int
  let comparer: (Int, Int) -> Bool

  init?(_ expected: String) {
    let regex = try! Regex(pattern: "exit code (equals|greater than|less than|greater than or equals|less than or equals) ([0-9]+)")
    guard regex.matches(expected) else {
      return nil
    }

    guard let comparer = regex.groups(expected).first, let exitCodeString = regex.groups(expected).last, let exitCode = Int(exitCodeString) else {
      return nil
    }

    self.exitCode = exitCode

    switch comparer {
      case "greater than": self.comparer = { $0 > $1 }
      case "less than": self.comparer = { $0 < $1 }
      case "greater than or equals": self.comparer = { $0 >= $1 }
      case "less than or equals": self.comparer = { $0 <= $1 }
      default: self.comparer = { $0 == $1 }
    }
  }

  func test(exitCode: Int32, stdOut: String, stdErr: String) -> Bool {
    return self.comparer(self.exitCode, Int(exitCode))
  }

}

struct OutputResult: ExpectedResult {

  let value: String
  let operation: String

  init?(_ expected: String) {
    let regex = try! Regex(pattern: "output (equas|contains|doesn't contain) '([^']+)'")
    guard regex.matches(expected) else {
      return nil
    }

    guard regex.matches(expected) else {
      return nil
    }

    guard let operation = regex.groups(expected).first, let value = regex.groups(expected).last else {
      return nil
    }

    self.value = value
    self.operation = operation
  }

  func test(exitCode: Int32, stdOut: String, stdErr: String) -> Bool {
    switch self.operation {
      case "equals": return stdOut == self.value
      case "contains": return stdOut.contains(self.value)
      default: return !stdOut.contains(self.value)
    }
  }

}

private struct SumResult: ExpectedResult {

  let lhs: ExpectedResult
  let rhs: ExpectedResult

  init?(_ expected: String) {
    return nil
  }

  init(lhs: ExpectedResult, rhs: ExpectedResult) {
    self.lhs = lhs
    self.rhs = rhs
  }

  func test(exitCode: Int32, stdOut: String, stdErr: String) -> Bool {
    return self.lhs.test(exitCode: exitCode, stdOut: stdOut, stdErr: stdErr) && self.rhs.test(exitCode: exitCode, stdOut: stdOut, stdErr: stdErr)
  }

}

func +(lhs: ExpectedResult, rhs: ExpectedResult) -> ExpectedResult {
  return SumResult(lhs: lhs, rhs: rhs)
}
