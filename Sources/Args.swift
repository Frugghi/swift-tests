import Foundation

enum ArgsError: Error {
  case MissingRequired
}

class Args {

  class func parse() throws -> (tests: String, template: String) {
    var args: [String: String] = [:]
    var parsing: String?

    for argument in CommandLine.arguments.dropFirst() {
      switch (argument, parsing) {
        case (_, .some(let value)):
          args[value] = argument
          parsing = nil
        default: parsing = argument
      }
    }

    guard let template = args["--template"] else {
      throw ArgsError.MissingRequired
    }

    guard let tests = args["--tests"] else {
      throw ArgsError.MissingRequired
    }

    return (tests: tests, template: template)
  }

  class func help() -> String {
    return "Must be invoked with: --tests <tests file> --template <template file>"
  }

}
