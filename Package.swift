// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwifTeaUI",
    platforms: [.macOS(.v14)],
    products: [
        // Users typically `import SwifTeaUI` for the runtime + DSL
        .library(name: "SwifTeaUI", targets: ["SwifTeaUI"]),
        .executable(name: "SwifTeaGalleryExample", targets: ["SwifTeaGalleryExample"]),
        .executable(name: "SwifTeaPerfHarness", targets: ["SwifTeaPerfHarness"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", revision: "98430f2d6cb8d817b60ea1489ad18db87cc547aa")
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
            name: "SwifTeaGalleryExampleTests",
            dependencies: [
                "GalleryExample",
                "SnapshotTestSupport",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ],
)
