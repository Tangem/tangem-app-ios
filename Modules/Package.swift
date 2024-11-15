// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Package

let package = Package(
    name: modulesWrapperLibraryName,
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: modulesWrapperLibraryName,
            targets: [
                modulesWrapperLibraryName,
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
    ],
    targets: [modulesWrapperLibrary] + serviceModules + featureModules + unitTestsModules
)

// MARK: - Service Modules

/// Valid examples are `CommonUI`, `Utils`, `NetworkLayer`, `ModelData`, etc.
var serviceModules: [PackageDescription.Target] {
    [
        .tangemTarget(
            name: "TangemFoundation",
            swiftSettings: [
                // TODO: Andrey Fedorov - Remove after migration to Swift 6 structured concurrency (IOS-8369)
//                .swiftLanguageMode(.v5),
            ]
        ),
        .tangemTarget(
            name: "TangemNetworkUtils",
            dependencies: [
                "Moya",
                "Alamofire",
            ],
            swiftSettings: [
                // TODO: Andrey Fedorov - Remove after migration to Swift 6 structured concurrency (IOS-8369)
//                .swiftLanguageMode(.v5),
            ]
        ),
    ]
}

// MARK: - Feature Modules

/// Valid examples are `Onboarding`, `Auth`, `Catalog`, etc.
var featureModules: [PackageDescription.Target] {
    [
        // Currently there are no feature modules
    ]
}

// MARK: - Unit Test Modules

var unitTestsModules: [PackageDescription.Target] {
    [
        .tangemTestTarget(
            name: "TangemFoundationTests",
            dependencies: [
                "TangemFoundation",
            ]
        ),
    ]
}

// MARK: - Wrapper Library (implementation details, do not edit)

var modulesWrapperLibraryName: String { "TangemModules" }

var modulesWrapperLibrary: PackageDescription.Target {
    .tangemTarget(
        name: modulesWrapperLibraryName,
        dependencies: serviceModules.asDependencies() + featureModules.asDependencies()
    )
}

// MARK: - Private implementation

private extension PackageDescription.Target {
    /// Just a dumb wrapper that sets the module `path` to the value of the module `name`.
    static func tangemTarget(
        name: String,
        dependencies: [PackageDescription.Target.Dependency] = [],
        exclude: [String] = [],
        sources: [String]? = nil,
        resources: [PackageDescription.Resource]? = nil,
        publicHeadersPath: String? = nil,
        packageAccess: Bool = true,
        cSettings: [PackageDescription.CSetting]? = nil,
        cxxSettings: [PackageDescription.CXXSetting]? = nil,
        swiftSettings: [PackageDescription.SwiftSetting]? = nil,
        linkerSettings: [PackageDescription.LinkerSetting]? = nil,
        plugins: [PackageDescription.Target.PluginUsage]? = nil
    ) -> PackageDescription.Target {
        let path = name

        return target(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            resources: resources,
            publicHeadersPath: publicHeadersPath,
            packageAccess: packageAccess,
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings,
            plugins: plugins
        )
    }

    /// Just a dumb wrapper that sets the module `path` to the value of the module `name`.
    static func tangemTestTarget(
        name: String,
        dependencies: [PackageDescription.Target.Dependency] = [],
        exclude: [String] = [],
        sources: [String]? = nil,
        resources: [PackageDescription.Resource]? = nil,
        packageAccess: Bool = true,
        cSettings: [PackageDescription.CSetting]? = nil,
        cxxSettings: [PackageDescription.CXXSetting]? = nil,
        swiftSettings: [PackageDescription.SwiftSetting]? = nil,
        linkerSettings: [PackageDescription.LinkerSetting]? = nil,
        plugins: [PackageDescription.Target.PluginUsage]? = nil
    ) -> PackageDescription.Target {
        let path = name

        return testTarget(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            resources: resources,
            packageAccess: packageAccess,
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings,
            plugins: plugins
        )
    }
}

private extension Array where Element == PackageDescription.Target {
    func asDependencies() -> [PackageDescription.Target.Dependency] {
        return map { .target(name: $0.name) }
    }
}
