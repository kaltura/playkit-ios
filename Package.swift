// swift-tools-version:5.3

import PackageDescription

let package = Package( 
    name: "PlayKit",
    platforms: [.iOS(.v11),
                .tvOS(.v11)],
    products: [.library(name: "PlayKit",
                        targets: ["PlayKit"]),
               .library(name: "AnalyticsCommon",
                        targets: ["AnalyticsCommon"])],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", .upToNextMajor(from: "7.0.0")),
        .package(name: "PlayKitUtils",
                 url: "https://github.com/kaltura/playkit-ios-utils.git",
                 .branch("FEC-12640")),
        .package(name: "KalturaNetKit",
                 url: "https://github.com/kaltura/netkit-ios.git",
                 .branch("FEC-12640")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
    ],
    targets: [.target(name: "PlayKit",
                      dependencies:
                        [
                            "SwiftyJSON",
                            "XCGLogger",
                            .product(name: "PlayKitUtils", package: "PlayKitUtils"),
                            .product(name: "KalturaNetKit", package: "KalturaNetKit"),
                        ],
                      path: "Classes/"),
              .target(name: "AnalyticsCommon",
                      dependencies: ["PlayKit"],
                      path: "Plugins/AnalyticsCommon/"),
              .testTarget(name: "PlayKitTests",
                          dependencies: ["PlayKit", "Quick", "Nimble"],
                          path: "Example/Tests/Basic",
                          exclude: [])
    ]
)
