// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WeatherDomainKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherDomain",
            targets: ["WeatherDomain"]
        )
    ],
    targets: [
        .target(
            name: "WeatherDomain"
        ),
        .testTarget(
            name: "WeatherDomainTests",
            dependencies: ["WeatherDomain"]
        )
    ]
)
