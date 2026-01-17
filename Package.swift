// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "InputRemapper",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "input-remapper", targets: ["InputRemapper"])
    ],
    targets: [
        .executableTarget(
            name: "InputRemapper",
            path: "Sources/InputRemapper"
        )
    ]
)
