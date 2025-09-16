// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PureMetrics",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PureMetrics",
            targets: ["PureMetrics"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.2.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "9.0.0")
    ],
    targets: [
        .target(
            name: "PureMetrics",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ]
        ),
    ]
)
