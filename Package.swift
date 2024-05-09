// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ALMARIK",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ALMARIK",
            targets: ["ALMARIK"]),
    ],
    dependencies: [
        // Add the dependency on the Google Maps SDK package
        .package(url: "https://github.com/googlemaps/google-maps-ios-sdk.git", from: "8.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ALMARIK",
            dependencies: ["GoogleMaps"]),
        .testTarget(
            name: "ALMARIKTests",
            dependencies: ["ALMARIK"]),
    ]
)
