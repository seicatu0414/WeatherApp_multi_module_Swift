// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WeatherForecastFeatureKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherForecastFeature",
            targets: ["WeatherForecastFeature"]
        )
    ],
    dependencies: [
        .package(path: "../WeatherDomainKit")
    ],
    targets: [
        .target(
            name: "WeatherForecastFeature",
            dependencies: [
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        ),
        .testTarget(
            name: "WeatherForecastFeatureTests",
            dependencies: [
                "WeatherForecastFeature",
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        )
    ]
)
