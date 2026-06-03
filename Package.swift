// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "sweepline-elements",
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
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "5.0.0"),
        
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
