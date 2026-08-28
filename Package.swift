// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KLPageCurl",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "KLPageCurl", targets: ["KLPageCurl"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.5.0"
        ),
    ],
    targets: [
        .target(name: "KLPageCurl"),
        .testTarget(name: "KLPageCurlTests", dependencies: ["KLPageCurl"]),
    ]
)
