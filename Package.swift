// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Managers",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Managers",
            targets: ["Managers"]),
    ],
    dependencies: [
        .package(url: "https://github.com/arman095095/NetworkServices.git", branch: "develop")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Managers",
            dependencies: [.product(name: "NetworkServices", package: "NetworkServices")]),
    ]
)
