// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let shimPackageName = "TangemDependenciesShim"

// TODO: Andrey Fedorov - Update swift-tools-version to 6.0 after upgrade to Xcode 16.0
let package = Package(
    name: shimPackageName,
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: shimPackageName,
            targets: [
                shimPackageName,
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
    ],
    targets: [
        .tangemTarget(
            name: shimPackageName,
            dependencies: [
                "TangemModule1",
                "TangemModule2",
                "TangemFoundation",
                "TangemNetworkLayerAdditions",
            ]
        ),
        .tangemTarget(
            name: "TangemModule1"
        ),
        .tangemTarget(
            name: "TangemModule2"
        ),
        .tangemTarget(
            name: "TangemFoundation"
        ),
        .tangemTestTarget(
            name: "TangemFoundationTests",
            dependencies: [
                "TangemFoundation",
            ]
        ),
        .tangemTarget(
            name: "TangemNetworkLayerAdditions",
            dependencies: [
                "Moya",
                "Alamofire",
            ]
        ),
    ]
)

// MARK: - Private implementation

private extension Target {
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
