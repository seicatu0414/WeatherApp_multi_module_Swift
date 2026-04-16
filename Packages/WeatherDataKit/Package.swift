// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WeatherDataKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherData",
            targets: ["WeatherData"]
        )
    ],
    dependencies: [
        .package(path: "../WeatherDomainKit")
    ],
    targets: [
        .target(
            name: "WeatherData",
            dependencies: [
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        ),
        .testTarget(
            name: "WeatherDataTests",
            dependencies: [
                "WeatherData",
                .product(name: "WeatherDomain", package: "WeatherDomainKit")
            ]
        )
    ]
)
