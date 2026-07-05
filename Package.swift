// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "sweep-beep",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    // Signing
    
    .library(
      name: "BeepSigning",
      targets: ["BeepSigning"]
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
    
    // Legacy
    
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
      name: "BeepSigning",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto")
      ],
      path: "Sources/SweeplineSigning",
    ),
    .target(
      name: "Sweepline",
      dependencies: [
        "BeepSigning",
      ],
      path: "Sources/Protocol/Sweepline",
    ),
    .target(
      name: "Sweetfeet",
      dependencies: [
        "BeepSigning"
      ],
      path: "Sources/Protocol/Sweetfeet",
    ),
    .target(
      name: "Beeper",
      dependencies: [
        "BeepSigning"
      ],
      path: "Sources/Protocol/Beeper",
    ),
    .target(
      name: "SweeplineSigning",
      dependencies: [
        "BeepSigning"
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
        "BeepSigning",
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
