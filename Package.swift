// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwifTeaUI",
    platforms: [.macOS(.v14)],
    products: [
        // Users typically `import SwifTeaUI` (which depends on SwifTeaCore)
        .library(name: "SwifTeaUI", targets: ["SwifTeaUI"]),
        .library(name: "SwifTeaCore", targets: ["SwifTeaCore"]),
        .executable(name: "SwifTeaNotebookExample", targets: ["SwifTeaNotebookExample"]),
        .executable(name: "SwifTeaTaskRunnerExample", targets: ["SwifTeaTaskRunnerExample"]),
        .executable(name: "SwifTeaPackageListExample", targets: ["SwifTeaPackageListExample"]),
        .executable(name: "SwifTeaShowcaseExample", targets: ["SwifTeaShowcaseExample"])
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
        .target(
            name: "NotebookExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/Notebook"
        ),
        .target(
            name: "TaskRunnerExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/TaskRunner"
        ),
        .target(
            name: "PackageListExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/PackageList"
        ),
        .target(
            name: "ShowcaseExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/Showcase"
        ),
        .executableTarget(
            name: "SwifTeaNotebookExample",
            dependencies: ["NotebookExample"],
            path: "Sources/ExampleApps/Notebook"
        ),
        .executableTarget(
            name: "SwifTeaTaskRunnerExample",
            dependencies: ["TaskRunnerExample"],
            path: "Sources/ExampleApps/TaskRunner"
        ),
        .executableTarget(
            name: "SwifTeaPackageListExample",
            dependencies: ["PackageListExample"],
            path: "Sources/ExampleApps/PackageList"
        ),
        .executableTarget(
            name: "SwifTeaShowcaseExample",
            dependencies: ["ShowcaseExample"],
            path: "Sources/ExampleApps/Showcase"
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
                "NotebookExample",
                "SnapshotTestSupport",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "SwifTeaTaskRunnerExampleTests",
            dependencies: [
                "TaskRunnerExample",
                "SnapshotTestSupport",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ],
)
