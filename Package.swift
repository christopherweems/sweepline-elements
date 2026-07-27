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
    // Signing
    
    .library(
      name: "SweeplineSigning",
      targets: ["SweeplineSigning"]
    ),
    
    // Protocols
    
    .library(
      name: "Sweepline",
      targets: ["Sweepline"]
    ),
    .library(
      name: "Sweetfeet",
      targets: ["Sweetfeet"]
    ),
    .library(
      name: "BeeperProtocol",
      targets: ["BeeperProtocol"]
    ),
    
    // Compatibility
    
    .library(
      name: "SweeplineElements",
      targets: ["SweeplineElements"]
    ),
    .library(
      name: "SweetfeetElements",
      targets: ["SweetfeetElements"]
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
      path: "Sources/Signing",
    ),
    .target(
      name: "Sweepline",
      dependencies: [
        "SweeplineSigning",
      ],
      path: "Sources/Protocol/Sweepline",
    ),
    .target(
      name: "Sweetfeet",
      dependencies: [
        "SweeplineSigning"
      ],
      path: "Sources/Protocol/Sweetfeet",
    ),
    .target(
      name: "BeeperProtocol",
      dependencies: [
        "SweeplineSigning"
      ],
      path: "Sources/Protocol/Beeper",
    ),
    .target(
      name: "SweeplineElements",
      dependencies: [
        "Sweepline",
        "SweeplineSigning",
      ],
      path: "Sources/Compatibility/SweeplineElements",
    ),
    .target(
      name: "SweetfeetElements",
      dependencies: [
        "Sweetfeet",
        "SweeplineSigning",
      ],
      path: "Sources/Compatibility/SweetfeetElements",
    ),
    .testTarget(
      name: "SweeplineElementsTests",
      dependencies: [
        "Sweepline",
        "Sweetfeet",
        "BeeperProtocol",
        "SweeplineElements",
        "SweetfeetElements",
        "SweeplineSigning",
        .product(name: "Crypto", package: "swift-crypto"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6],
)
