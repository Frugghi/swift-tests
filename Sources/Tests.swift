import Foundation
import POSIXRegex
import Yaml

class Tests {
  private var tests: [Test] = []

  func add(test: Test) {
    self.tests.append(test)
  }

  func find(with label: String) -> [Test] {
    return self.tests.filter { $0.label == label }
  }

  subscript(label: String) -> [Test] {
    let tests = self.find(with: label)
    return tests.isEmpty ? [ Test(label: label, command: "").markMissing() ] : tests
  }

  func run(_ label: String) -> [(test: Test, result: TestResult)] {
    return self[label].map {
      ($0, self.run($0))
    }
  }

  func run(_ test: Test) -> TestResult {
    print("Testing \(test.name)")

    if test.skip {
      return TestResult(status: .NotTested)
    }

    return test.run()
  }

  func runAll() -> [(test: Test, result: TestResult)] {
    return self.tests.map {
      ($0, self.run($0))
    }
  }

}

extension Tests {

  static func parse(_ path: String) -> Tests {
    let tests = Tests()

    do {
      let contents = try String(contentsOfFile: path, encoding: .utf8)
      try Yaml.loadMultiple(contents).flatMap {
        guard let label = $0["label"].string, let command = $0["command"].string?.characters.split(separator: " ").map(String.init) else {
          return nil
        }
        let name = $0["name"].string

        let test = Test(label: label, name: name, expected: $0["expect"].string, command: command)

        print("Parsing \(test)")

        if let note = $0["notes"].string {
          test.addNote(note)
        } else if let notes = $0["notes"].array {
          test.addNotes(notes.flatMap({ $0.string }))
        }

        if let expected = $0["expect"].string {
          let results: [ExpectedResult.Type] = [ ExitCodeResult.self, OutputResult.self ]

          var expectedResult: ExpectedResult? = nil
          expected.components(separatedBy: " and ").forEach {
            for result in results {
              guard let result = result.init($0) else {
                continue
              }

              if expectedResult == nil {
                expectedResult = result
              } else {
                expectedResult = expectedResult! + result
              }
            }
          }

          if let expectedResult = expectedResult {
            test.supportedIf(expectedResult)
          }
        }

        if let skip = $0["skip"].bool, skip {
          test.markDoNotRun()
        }

        if let pre = $0["pre"].string {
          test.pre(pre)
        } else if let pre = $0["pre"].array {
          test.pre(pre.flatMap({ $0.string }))
        }

        if let post = $0["post"].string {
          test.post(post)
        } else if let post = $0["post"].array {
          test.post(post.flatMap({ $0.string }))
        }

        return test
      }.forEach { test in
        tests.add(test: test)
      }
    } catch {
      print("\(error)")
    }

    return tests
  }

}
