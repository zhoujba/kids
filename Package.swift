// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KidsScheduleApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "KidsScheduleApp",
            targets: ["KidsScheduleApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "KidsScheduleApp",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "AsyncKit", package: "async-kit")
            ]
        ),
    ]
)
