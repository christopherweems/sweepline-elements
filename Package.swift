// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "beepline-elements",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    // Signing
    
    .library(
      name: "BeeplineSigning",
      targets: ["BeeplineSigning"]
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
      name: "Beeper",
      targets: ["Beeper"]
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
      name: "BeeplineSigning",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto")
      ],
      path: "Sources/Signing",
    ),
    .target(
      name: "Sweepline",
      dependencies: [
        "BeeplineSigning",
      ],
      path: "Sources/Protocol/Sweepline",
    ),
    .target(
      name: "Sweetfeet",
      dependencies: [
        "BeeplineSigning"
      ],
      path: "Sources/Protocol/Sweetfeet",
    ),
    .target(
      name: "Beeper",
      dependencies: [
        "BeeplineSigning"
      ],
      path: "Sources/Protocol/Beeper",
    ),
    .target(
      name: "SweeplineSigning",
      dependencies: [
        "BeeplineSigning"
      ],
      path: "Sources/Compatibility/SweeplineSigning",
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
        "BeeplineSigning",
        "Sweepline",
        "Sweetfeet",
        "Beeper",
        "SweeplineElements",
        "SweetfeetElements",
        "SweeplineSigning",
        .product(name: "Crypto", package: "swift-crypto"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6],
)
