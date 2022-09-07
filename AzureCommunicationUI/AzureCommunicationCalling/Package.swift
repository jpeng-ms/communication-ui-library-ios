// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AzureCommunicationCalling",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "AzureCommunicationCalling",
            targets: ["AzureCommunicationCalling"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "AzureCommunicationCalling",
            url: "https://github.com/Azure/Communication/releases/download/v2.2.0/AzureCommunicationCalling-2.2.0.zip",
            checksum: "82af7eddc193c22e729373b713b1328efbf784c0cecb83b3e217996c9547f298"
        )
    ]
)
