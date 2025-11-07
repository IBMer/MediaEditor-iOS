// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImPAWsibleMetalFilters",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Core Metal filter processing library
        .library(
            name: "ImPAWsibleMetalFilters",
            targets: ["ImPAWsibleMetalFilters"]
        ),
        // SwiftUI components (optional)
        .library(
            name: "ImPAWsibleMetalFiltersUI",
            targets: ["ImPAWsibleMetalFiltersUI"]
        ),
    ],
    dependencies: [
        // No external dependencies - pure Swift & Metal
    ],
    targets: [
        // Core Metal filter processing target
        .target(
            name: "ImPAWsibleMetalFilters",
            dependencies: [],
            resources: [
                .process("Shaders")
            ]
        ),

        // SwiftUI UI components target
        .target(
            name: "ImPAWsibleMetalFiltersUI",
            dependencies: ["ImPAWsibleMetalFilters"]
        ),

        // Tests
        .testTarget(
            name: "ImPAWsibleMetalFiltersTests",
            dependencies: ["ImPAWsibleMetalFilters"]
        ),
    ]
)
