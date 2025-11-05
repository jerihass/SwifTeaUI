// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwifTeaUI",
    platforms: [.iOS(.v16)],
    products: [
        // Users typically `import SwifTeaUI` (which depends on SwifTeaCore)
        .library(name: "SwifTeaUI", targets: ["SwifTeaUI"]),
        .library(name: "SwifTeaCore", targets: ["SwifTeaCore"]),
        .executable(name: "SwifTeaCounterExample", targets: ["SwifTeaCounterExample"]),
        .executable(name: "SwifTeaNotebookExample", targets: ["SwifTeaNotebookExample"]),
        .executable(name: "SwifTeaTaskRunnerExample", targets: ["SwifTeaTaskRunnerExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", branch: "main")
    ],
    targets: [
        .target(
            name: "SwifTeaCore",
            path: "Sources/SwifTeaCore"
        ),
        .target(
            name: "SwifTeaUI",
            dependencies: ["SwifTeaCore"],
            path: "Sources/SwifTeaUI"
        ),
        .executableTarget(
            name: "SwifTeaCounterExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/Counter"
        ),
        .executableTarget(
            name: "SwifTeaNotebookExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/Notebook"
        ),
        .executableTarget(
            name: "SwifTeaTaskRunnerExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/TaskRunner"
        ),
        .target(
            name: "SnapshotTestSupport",
            dependencies: [
                "SwifTeaUI",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/TestSupport"
        ),
        .testTarget(
            name: "SwifTeaCoreTests",
            dependencies: [
                "SwifTeaCore",
                "SwifTeaUI",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "SwifTeaUITests",
            dependencies: [
                "SwifTeaUI",
                "SnapshotTestSupport",
                .product(name:"Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "SwifTeaNotebookExampleTests",
            dependencies: [
                "SwifTeaNotebookExample",
                "SnapshotTestSupport",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "SwifTeaTaskRunnerExampleTests",
            dependencies: [
                "SwifTeaTaskRunnerExample",
                "SnapshotTestSupport",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
