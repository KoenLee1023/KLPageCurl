// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PhotoAlbumDemo",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PhotoAlbumDemoModel", targets: ["PhotoAlbumDemoApp"]),
    ],
    dependencies: [
        .package(name: "KLPageCurl", path: "../.."),
    ],
    targets: [
        .target(
            name: "PhotoAlbumDemoApp",
            dependencies: [
                .product(name: "KLPageCurl", package: "KLPageCurl"),
            ]
        ),
        .testTarget(
            name: "PhotoAlbumDemoTests",
            dependencies: ["PhotoAlbumDemoApp"]
        ),
    ]
)
