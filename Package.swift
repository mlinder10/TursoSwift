// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TursoSwift",
    platforms: [
      .macOS(.v12),
      .iOS(.v13),
      .visionOS(.v1),
      .watchOS(.v4),
      .driverKit(.v19),
      .tvOS(.v12),
      .macCatalyst(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TursoSwift",
            targets: ["TursoSwift"]),
    ],
    dependencies: [
      .package(
        url: "https://github.com/thebarndog/swift-dotenv.git",
        .upToNextMajor(from: "2.0.0")
      )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TursoSwift"),
        .testTarget(
            name: "TursoSwiftTests",
            dependencies: [
              "TursoSwift",
              .product(
                name: "SwiftDotenv",
                package: "swift-dotenv"
              )
            ]
          ),
    ]
)
