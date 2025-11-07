// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImPAWsibleMetalFilters",
    platforms: [
        .iOS(.v17),  // 与 DuoMira 保持一致
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ImPAWsibleMetalFilters",
            targets: ["ImPAWsibleMetalFilters"]
        )
    ],
    dependencies: [
        // 无外部依赖 - 仅使用系统框架
    ],
    targets: [
        .target(
            name: "ImPAWsibleMetalFilters",
            dependencies: [],
            path: "Sources/ImPAWsibleMetalFilters"
        ),
        .testTarget(
            name: "ImPAWsibleMetalFiltersTests",
            dependencies: ["ImPAWsibleMetalFilters"],
            path: "Tests/ImPAWsibleMetalFiltersTests"
        )
    ]
)
