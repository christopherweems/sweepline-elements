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
    .library(
      name: "SweetfeetElements",
      targets: ["SweetfeetElements"]
    ),
    .library(
      name: "SweeplineSigning",
      targets: ["SweeplineSigning"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"5.0.0")

  ],
  targets: [
    .target(
      name: "SweeplineSigning",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto")
      ],
    ),
    .target(
      name: "SweeplineElements",
      dependencies: [
        "SweeplineSigning",
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      path: "Sources/Protocol/Sweepline",
    ),
    .target(
      name: "SweetfeetElements",
      dependencies: [
        "SweeplineSigning"
      ],
      path: "Sources/Protocol/Sweetfeet",
    ),
    .testTarget(
      name: "SweeplineElementsTests",
      dependencies: [
        "SweeplineElements",
        "SweetfeetElements",
        "SweeplineSigning",
        .product(name: "Crypto", package: "swift-crypto"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6],
)
