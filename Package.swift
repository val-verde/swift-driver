// swift-tools-version:5.1
import PackageDescription
import class Foundation.ProcessInfo

let macOSPlatform: SupportedPlatform
if let deploymentTarget = ProcessInfo.processInfo.environment["SWIFTPM_MACOS_DEPLOYMENT_TARGET"] {
    macOSPlatform = .macOS(deploymentTarget)
} else {
    macOSPlatform = .macOS(.v10_15)
}

let package = Package(
  name: "swift-driver",
  platforms: [
    macOSPlatform,
  ],
  products: [
    .executable(
      name: "swift-driver",
      targets: ["swift-driver"]),
    .executable(
      name: "swift-help",
      targets: ["swift-help"]),
    .executable(
      name: "swift-build-sdk-interfaces",
      targets: ["swift-build-sdk-interfaces"]),
    .library(
      name: "SwiftDriver",
      targets: ["SwiftDriver"]),
    .library(
      name: "SwiftDriverDynamic",
      type: .dynamic,
      targets: ["SwiftDriver"]),
    .library(
      name: "SwiftOptions",
      targets: ["SwiftOptions"]),
    .library(
      name: "SwiftDriverExecution",
      targets: ["SwiftDriverExecution"]),
  ],
  targets: [

    /// C modules wrapper for _InternalLibSwiftScan.
    .target(name: "CSwiftScan"),

    /// The driver library.
    .target(
      name: "SwiftDriver",
      dependencies: ["SwiftOptions", "SwiftToolsSupport-auto",
                     "CSwiftScan", "Yams"]),

    /// The execution library.
    .target(
      name: "SwiftDriverExecution",
      dependencies: ["SwiftDriver", "SwiftToolsSupport-auto"]),

    /// Driver tests.
    .testTarget(
      name: "SwiftDriverTests",
      dependencies: ["SwiftDriver", "SwiftDriverExecution", "swift-driver",
                     "TestUtilities"]),

    /// IncrementalImport tests
    .testTarget(
      name: "IncrementalImportTests",
      dependencies: ["IncrementalTestFramework", "TestUtilities", "SwiftToolsSupport-auto"]),

    .target(
      name: "IncrementalTestFramework",
      dependencies: [ "SwiftDriver", "SwiftOptions", "TestUtilities" ],
      path: "Tests/IncrementalTestFramework",
      linkerSettings: [
        .linkedFramework("XCTest", .when(platforms: [.iOS, .macOS, .tvOS, .watchOS]))
      ]),

    .target(
      name: "TestUtilities",
      dependencies: ["SwiftDriver", "SwiftDriverExecution"],
      path: "Tests/TestUtilities"),

    /// The options library.
    .target(
      name: "SwiftOptions",
      dependencies: ["SwiftToolsSupport-auto"]),
    .testTarget(
      name: "SwiftOptionsTests",
      dependencies: ["SwiftOptions"]),

    /// The primary driver executable.
    .target(
      name: "swift-driver",
      dependencies: ["SwiftDriverExecution", "SwiftDriver"]),

    /// The help executable.
    .target(
      name: "swift-help",
      dependencies: ["SwiftOptions", "ArgumentParser", "SwiftToolsSupport-auto"]),

    /// The help executable.
    .target(
      name: "swift-build-sdk-interfaces",
      dependencies: ["SwiftDriver", "SwiftDriverExecution"]),

    /// The `makeOptions` utility (for importing option definitions).
    .target(
      name: "makeOptions",
      dependencies: []),
  ],
  cxxLanguageStandard: .cxx14
)

if ProcessInfo.processInfo.environment["SWIFT_DRIVER_LLBUILD_FWK"] == nil {
    if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
        package.dependencies += [
            .package(url: "https://github.com/val-verde/swift-llbuild.git", .branch("val-verde-mainline-next")),
        ]
    } else {
        // In Swift CI, use a local path to llbuild to interoperate with tools
        // like `update-checkout`, which control the sources externally.
        package.dependencies += [
            .package(path: "../llbuild"),
        ]
    }
    package.targets.first(where: { $0.name == "SwiftDriverExecution" })!.dependencies += ["llbuildSwift"]
}

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  package.dependencies += [
    .package(url: "https://github.com/val-verde/swift-tools-support-core.git", .branch("val-verde-mainline-next")),
    .package(url: "https://github.com/val-verde/Yams.git", .branch("val-verde-mainline-next")),
    // The 'swift-argument-parser' version declared here must match that
    // used by 'swift-package-manager' and 'sourcekit-lsp'. Please coordinate
    // dependency version changes here with those projects.
    .package(url: "https://github.com/val-verde/swift-argument-parser.git", .branch("val-verde-mainline-next")),
  ]
} else {
    package.dependencies += [
        .package(path: "../swift-tools-support-core"),
        .package(path: "../yams"),
        .package(path: "../swift-argument-parser"),
    ]
}
