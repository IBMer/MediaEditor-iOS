// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImPAWsibleCoreImage",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Core filter processing library
        .library(
            name: "ImPAWsibleCoreImage",
            targets: ["ImPAWsibleCoreImage"]
        ),
        // SwiftUI components (optional)
        .library(
            name: "ImPAWsibleCoreImageUI",
            targets: ["ImPAWsibleCoreImageUI"]
        ),
    ],
    dependencies: [
        // No external dependencies - pure Swift & Core Image
    ],
    targets: [
        // Core filter processing target
        .target(
            name: "ImPAWsibleCoreImage",
            dependencies: []
        ),

        // SwiftUI UI components target
        .target(
            name: "ImPAWsibleCoreImageUI",
            dependencies: ["ImPAWsibleCoreImage"]
        ),

        // Tests
        .testTarget(
            name: "ImPAWsibleCoreImageTests",
            dependencies: ["ImPAWsibleCoreImage"]
        ),
    ]
)
