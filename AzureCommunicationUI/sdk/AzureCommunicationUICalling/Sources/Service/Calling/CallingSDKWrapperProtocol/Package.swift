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
                "CallingSDKWrapperProtocol",
                "AzureCommunicationCalling"
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Azure/SwiftPM-AzureCommunicationCommon.git",
            exact: .init(1, 0, 3)
        ),
    ],
    targets: [
        .binaryTarget(
            name: "AzureCommunicationCalling",
            url: "https://github.com/Azure/Communication/releases/download/v2.4.0-alpha.1/AzureCommunicationCalling-2.4.0-alpha.1.zip",
            checksum: "2cfdf393e77869122f0d15d02938c3de9356ee59310eda580d81829259db6d17"
        ),
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
//        .binaryTarget(
//            name: "AzureCommunicationCalling",
//            url: "https://github.com/Azure/Communication/releases/download/v2.2.0/AzureCommunicationCalling-2.2.0.zip",
//            checksum: "82af7eddc193c22e729373b713b1328efbf784c0cecb83b3e217996c9547f298"
//        ),
        .testTarget(
            name: "CallingSDKWrapperProtocolTests",
            dependencies: ["CallingSDKWrapperProtocol"])
    ]
)
