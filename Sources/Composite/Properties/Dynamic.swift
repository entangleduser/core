#if canImport(SwiftUI)
 @_exported import protocol SwiftUI.DynamicProperty
#else
 public protocol DynamicProperty { mutating func update() }
#endif
