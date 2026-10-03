// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenConnectKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "OpenConnectKit", targets: ["OpenConnectKit"])
    ],
    targets: [
        // libopenconnect 9.21 + OpenSSL 3.6.5, static, iOS device + simulator (arm64).
        .binaryTarget(
            name: "openconnect",
            url: "https://github.com/themoein100/OpenConnectKit/releases/download/v9.21.0/openconnect.xcframework.zip",
            checksum: "75367b67697054dcd7eafb42552d529229394bd047121be29ee694b149127f97"
        ),
        // Tiny C layer: formats libopenconnect's variadic progress callback, which Swift cannot implement.
        .target(name: "COpenConnectShim", dependencies: ["openconnect"]),
        .target(
            name: "OpenConnectKit",
            dependencies: ["openconnect", "COpenConnectShim"],
            linkerSettings: [.linkedLibrary("xml2"), .linkedLibrary("z"), .linkedLibrary("iconv")]
        )
    ]
)
