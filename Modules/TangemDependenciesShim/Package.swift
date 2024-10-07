// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let shimPackageName = "TangemDependenciesShim"

// TODO: Andrey Fedorov - Update swift-tools-version to 6.0
let package = Package(
    name: shimPackageName,
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: shimPackageName,
            targets: [
                shimPackageName,
            ]
        ),
        .library(
            name: "TangemFoundation",
            targets: [
                "TangemFoundation",
            ]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: shimPackageName),
        .target(name: "TangemFoundation"),
    ]
)
