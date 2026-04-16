// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WeatherKitAppMVVM",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherDomainMVVM",
            targets: ["WeatherDomainMVVM"]
        ),
        .library(
            name: "WeatherDataMVVM",
            targets: ["WeatherDataMVVM"]
        ),
        .library(
            name: "WeatherFeatureMVVM",
            targets: ["WeatherFeatureMVVM"]
        ),
    ],
    targets: [
        .target(
            name: "WeatherDomainMVVM"
        ),
        .target(
            name: "WeatherDataMVVM",
            dependencies: ["WeatherDomainMVVM"]
        ),
        .target(
            name: "WeatherFeatureMVVM",
            dependencies: ["WeatherDomainMVVM", "WeatherDataMVVM"]
        ),
        .testTarget(
            name: "WeatherDomainMVVMTests",
            dependencies: ["WeatherDomainMVVM"]
        ),
    ]
)
