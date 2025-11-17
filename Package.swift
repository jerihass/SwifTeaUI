// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwifTeaUI",
    platforms: [.macOS(.v14)],
    products: [
        // Users typically `import SwifTeaUI` (which depends on SwifTeaCore)
        .library(name: "SwifTeaUI", targets: ["SwifTeaUI"]),
        .library(name: "SwifTeaCore", targets: ["SwifTeaCore"]),
        .executable(name: "SwifTeaGalleryExample", targets: ["SwifTeaGalleryExample"])
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
            name: "GalleryExample",
            dependencies: ["SwifTeaUI"],
            path: "Sources/Examples/Gallery"
        ),
        .executableTarget(
            name: "SwifTeaGalleryExample",
            dependencies: ["GalleryExample"],
            path: "Sources/ExampleApps/Gallery"
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
            name: "SwifTeaGalleryExampleTests",
            dependencies: [
                "GalleryExample",
                "SnapshotTestSupport",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ],
)
