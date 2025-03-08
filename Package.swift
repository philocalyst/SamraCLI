// swift-tools-version: 6.0

// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SamraCLI",
    platforms: [
        .macOS(.v10_15) // Set the minimum macOS version to 10.15
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "samra", // The name of the executable
            targets: ["SamraCLI"]
        )
    ],
    dependencies: [
        .package(path: "./PrivateKits") // Add local package dependency using path
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget( // Use executableTarget instead of target
            name: "SamraCLI",
            dependencies: [
                .product(name: "AssetCatalogWrapper", package: "PrivateKits") // Add the dependency on the product
            ]
        ),
        .testTarget(
            name: "SamraCLITests",
            dependencies: ["SamraCLI"]
        ),
    ]
)
