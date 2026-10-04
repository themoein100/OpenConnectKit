// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenConnectKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "OpenConnectKit", targets: ["OpenConnectKit"])
    ],
    targets: [
        // libopenconnect 9.21 (+ DTLS startup patch) + OpenSSL 3.6.5, static, iOS device + simulator (arm64).
        .binaryTarget(
            name: "openconnect",
            url: "https://github.com/themoein100/OpenConnectKit/releases/download/v9.21.3/openconnect.xcframework.zip",
            checksum: "e10dff0b9979feef3f05e4014832313b00ffa3e992a0ff13dbb0aaa07a19ee36"
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
