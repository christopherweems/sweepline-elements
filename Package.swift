// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "SweeplineElements",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "SweeplineElements",
            targets: ["SweeplineElements"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "SweeplineElements",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .testTarget(
            name: "SweeplineElementsTests",
            dependencies: [
                "SweeplineElements",
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6],
)
