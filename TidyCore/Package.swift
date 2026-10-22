// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TidyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TidyCore", targets: ["TidyCore"]),
    ],
    targets: [
        .target(name: "TidyCore"),
        .testTarget(name: "TidyCoreTests", dependencies: ["TidyCore"]),
    ]
)
