import PackageDescription

let package = Package(
    name: "swift-tests",
    dependencies: [
        .Package(url: "https://github.com/czechboy0/Tasks.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/behrang/YamlSwift.git", Version(3, 0, 0)),
        .Package(url: "https://github.com/IvanUshakov/POSIXRegex.git", majorVersion: 0, minor: 8)
    ]
)
