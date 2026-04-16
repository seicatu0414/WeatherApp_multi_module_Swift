// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WeatherKitApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherFeature",
            targets: ["WeatherFeature"]
        ),
    ], dependencies: [
        .package(path: "../WeatherDomainKit"),
        .package(path: "../WeatherDataKit"),
        .package(path: "../WeatherHomeFeatureKit"),
        .package(path: "../WeatherForecastFeatureKit"),
        .package(path: "../DailyForecastDetailFeatureKit")
    ],
    targets: [
        .target(
            name: "WeatherFeature",
            dependencies: [
                .product(name: "WeatherDomain", package: "WeatherDomainKit"),
                .product(name: "WeatherData", package: "WeatherDataKit"),
                .product(name: "WeatherHomeFeature", package: "WeatherHomeFeatureKit"),
                .product(name: "WeatherForecastFeature", package: "WeatherForecastFeatureKit"),
                .product(name: "DailyForecastDetailFeature", package: "DailyForecastDetailFeatureKit")
            ]
        ),
        .testTarget(
            name: "WeatherFeatureTests",
            dependencies: [
                "WeatherFeature",
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        ),
    ]
)
