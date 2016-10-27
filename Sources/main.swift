import Foundation

let templatePath: String
let testsPath: String

do {
  (testsPath, templatePath) = try Args.parse()
} catch {
  print(error)
  print(Args.help())
  exit(1)
}

let tests = Tests.parse(testsPath)

do {
  print("Running tests...")
  let results = tests.runAll()

  let template = MarkdownTemplate(path: templatePath)
  let output = try TemplateRenderer.render(results, with: template)
  let outputPath = URL(fileURLWithPath: testsPath).lastPathComponent.replacingOccurrences(of: ".yaml", with: ".md")

  try output.write(toFile: "Results/\(outputPath)", atomically: true, encoding: .utf8)
} catch {
  print(error)
}
