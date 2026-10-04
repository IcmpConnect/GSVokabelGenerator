// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GSVokabelGenerator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "GSVokabelGenerator",
            targets: ["GSVokabelGenerator"]
        )
    ],
    targets: [
        .executableTarget(
            name: "GSVokabelGenerator",
            path: "App",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "GSVokabelGeneratorTests",
            dependencies: ["GSVokabelGenerator"],
            path: "Tests"
        )
    ]
)
