// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WeatherHomeFeatureKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherHomeFeature",
            targets: ["WeatherHomeFeature"]
        )
    ],
    dependencies: [
        .package(path: "../WeatherDomainKit")
    ],
    targets: [
        .target(
            name: "WeatherHomeFeature",
            dependencies: [
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        ),
        .testTarget(
            name: "WeatherHomeFeatureTests",
            dependencies: [
                "WeatherHomeFeature",
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        )
    ]
)
