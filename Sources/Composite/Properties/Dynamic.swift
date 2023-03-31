#if canImport(SwiftUI)
 @_exported import protocol SwiftUI.DynamicProperty
#else
 protocol DynamicProperty { mutating func update() }
#endif
