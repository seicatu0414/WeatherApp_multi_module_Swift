// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "DailyForecastDetailFeatureKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DailyForecastDetailFeature",
            targets: ["DailyForecastDetailFeature"]
        )
    ],
    dependencies: [
        .package(path: "../WeatherDomainKit")
    ],
    targets: [
        .target(
            name: "DailyForecastDetailFeature",
            dependencies: [
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        ),
        .testTarget(
            name: "DailyForecastDetailFeatureTests",
            dependencies: [
                "DailyForecastDetailFeature",
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        )
    ]
)
