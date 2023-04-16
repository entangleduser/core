// swift-tools-version: 5.5

import PackageDescription

let package = Package(
 name: "Core",
 products: [
  .library(name: "Reflection", targets: ["Reflection"]),
  .library(name: "Core", targets: ["Core"]),
  .library(name: "Extensions", targets: ["Extensions"]),
  .library(name: "Transactions", targets: ["Transactions"]),
  .library(name: "Composite", targets: ["Composite"]),
  .library(name: "Components", targets: ["Components"])
 ],
 dependencies: [
//  .package(path: "../Github/OpenCombine"),
//  .package(path: "../Github/Swift/swift-numerics"),
//  .package(path: "../Github/Swift/swift-atomics"),
//  .package(path: "../Github/Swift/swift-collections")
  .package(url: "https://github.com/OpenCombine/OpenCombine", branch: "master"),
  .package(url: "https://github.com/apple/swift-numerics", branch: "main"),
  .package(url: "https://github.com/apple/swift-atomics", branch: "main"),
  .package(url: "https://github.com/apple/swift-collections", branch: "main")
 ],
 targets: [
  .target(name: "Reflection"),
  .target(
   name: "Core",
   dependencies: [
    "OpenCombine",
    .product(name: "Atomics", package: "swift-atomics")
   ]
  ),
  .target(name: "Extensions", dependencies: ["Core"]),
  .target(
   name: "Composite",
   dependencies: [
    "Extensions", "Reflection", "Transactions",
    .product(name: "Collections", package: "swift-collections")
   ]
  ),
  .target(name: "Transactions", dependencies: ["Extensions"]),
  .target(
   name: "Components",
   dependencies: [
    "Extensions", .product(name: "Numerics", package: "swift-numerics")
   ]
  ),
  /* .testTarget(name: "CoreTests", dependencies: ["Core"]), */
  .testTarget(name: "ExtensionsTests", dependencies: ["Core", "Extensions"])
 ]
)
