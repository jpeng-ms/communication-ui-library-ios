// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CallingSDKWrapperProtocol",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "CallingSDKWrapperProtocol",
            type: .dynamic,
            targets: [
                "CallingSDKWrapperProtocol"
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Azure/SwiftPM-AzureCommunicationCommon.git",
            exact: .init(1, 0, 3)
        ),
        .package(path: "../AzureCommunicationCalling")
    ],
    targets: [
        .target(
            name: "CallingSDKWrapperProtocol",
            dependencies: [
                "AzureCommunicationCalling",
//                .product(
//                    name: "AzureCommunicationCommon",
//                    package: "SwiftPM-AzureCommunicationCommon"
//                )
            ]
//            linkerSettings: [
//                .linkedFramework("AzureCommunicationCommon"),
//                .unsafeFlags([
//                    "BUILD_LIBRARY_FOR_DISTRIBUTION=true"
//                ])
//            ]
        ),
        .testTarget(
            name: "CallingSDKWrapperProtocolTests",
            dependencies: ["CallingSDKWrapperProtocol"])
    ]
)
