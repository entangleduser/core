@_exported import Core
@_exported import struct Foundation.Date
typealias AnyPropertyKey = any PropertyKey
protocol PropertyKey: Hashable, CustomStringConvertible {
 associatedtype Value
}

extension PropertyKey {
 static var description: String { "\(Self.self)" }
 var description: String { Self.description }
}

typealias AnyResolvedKey = any ResolvedKey
protocol ResolvedKey: PropertyKey {
 associatedtype Value
 associatedtype ResolvedValue
 static func resolveValue(_ value: Value?) -> ResolvedValue
 static func storeValue(_ value: ResolvedValue?) -> Value?
}

extension ResolvedKey {
 static var resolvedValue: ResolvedValue { resolveValue(nil) }
 static var customMirror: Mirror {
  Mirror(Self.self, children: [description: resolveValue])
 }

 var resolvedValue: ResolvedValue { Self.resolveValue(nil) }
 func resolveValue(any value: Any?) -> Any {
  Self.resolveValue(value as? Value)
 }

 func storeValue(any value: Any?) -> Any? {
  Self.storeValue(value as? ResolvedValue)
 }
}

protocol OptionalKey: PropertyKey {
 override associatedtype Value
 typealias ResolvedValue = Value?
}

extension OptionalKey {
 static func resolveValue(_ value: Value?) -> Value? { nil }
 static func storeValue(_ value: ResolvedValue?) -> Value? { value ?? nil }
}

protocol DefaultKey: ResolvedKey where ResolvedValue == Value {
 override associatedtype ResolvedValue = Value
 static var defaultValue: Value { get }
}

extension DefaultKey {
 static func resolveValue(_ value: Value?) -> ResolvedValue { defaultValue }
 static func storeValue(_ value: ResolvedValue?) -> Value? {
  value ?? defaultValue
 }
}

extension DefaultKey where Value: Infallible {
 static var defaultValue: Value { Value.defaultValue }
}

protocol IntBoolKey: ResolvedKey {
 override associatedtype Value = Int
 override associatedtype ResolvedValue = Bool
}

extension IntBoolKey {
 static func resolveValue(_ value: Int?) -> Bool {
  guard let value else { return false }
  return value < 1 ? false : true
 }

 static func storeValue(_ value: Bool?) -> Int? {
  guard let value else { return .zero }
  return value ? 1 : .zero
 }
}

protocol DoubleDateKey: ResolvedKey {
 override associatedtype Value = Double
 override associatedtype ResolvedValue = Date?
}

extension DoubleDateKey {
 static func resolveValue(_ value: Double?) -> Date? {
  guard let value else { return nil }
  return Date(timeIntervalSinceReferenceDate: value)
 }

 static func storeValue(_ value: Date??) -> Double? {
  guard let value else { return nil }
  return value?.timeIntervalSinceReferenceDate
 }
}
