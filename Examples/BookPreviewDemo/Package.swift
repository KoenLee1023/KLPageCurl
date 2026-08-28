// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BookPreviewDemo",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .executable(name: "BookPreviewDemo", targets: ["BookPreviewDemoApp"]),
    ],
    dependencies: [
        .package(name: "KLPageCurl", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "BookPreviewDemoApp",
            dependencies: [
                .product(name: "KLPageCurl", package: "KLPageCurl"),
            ]
        ),
        .testTarget(
            name: "BookPreviewDemoTests",
            dependencies: ["BookPreviewDemoApp"]
        ),
    ]
)
