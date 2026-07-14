// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwifTeaUI",
    platforms: [.macOS(.v26)],
    products: [
        // Users typically `import SwifTeaUI` for the runtime + DSL
        .library(name: "SwifTeaUI", targets: ["SwifTeaUI"]),
        .executable(name: "SwifTeaGalleryExample", targets: ["SwifTeaGalleryExample"]),
        .executable(name: "SwifTeaPerfHarness", targets: ["SwifTeaPerfHarness"]),
        .executable(name: "SwifTeaLifecycleFixture", targets: ["SwifTeaLifecycleFixture"]),
    ],
    targets: [
        .target(
            name: "SwifTeaUI",
            dependencies: [],
            path: "Sources/SwifTeaUI"
        ),
        .target(
            name: "GalleryExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/Gallery"
        ),
        .executableTarget(
            name: "SwifTeaGalleryExample",
            dependencies: ["GalleryExample"],
            path: "Sources/ExampleApps/Gallery"
        ),
        .executableTarget(
            name: "SwifTeaPreviewDemo",
            dependencies: ["GalleryExample"],
            path: "Sources/ExampleApps/PreviewDemo"
        ),
        .executableTarget(
            name: "SwifTeaPerfHarness",
            dependencies: ["GalleryExample"],
            path: "Sources/ExampleApps/PerfHarness"
        ),
        .executableTarget(
            name: "SwifTeaLifecycleFixture",
            dependencies: ["SwifTeaUI"],
            path: "Sources/ExampleApps/LifecycleFixture"
        ),
        .target(
            name: "SnapshotTestSupport",
            dependencies: ["SwifTeaUI"],
            path: "Tests/TestSupport"
        ),
        .testTarget(
            name: "SwifTeaCoreTests",
            dependencies: ["SwifTeaUI"]
        ),
        .testTarget(
            name: "SwifTeaUITests",
            dependencies: ["SwifTeaUI", "SnapshotTestSupport"]
        ),
        .testTarget(
            name: "SwifTeaGalleryExampleTests",
            dependencies: ["GalleryExample", "SnapshotTestSupport"]
        ),
    ]
)
