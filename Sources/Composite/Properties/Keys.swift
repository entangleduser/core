@_exported import Core
import struct Foundation.Date
import struct Foundation.Data

public typealias AnyPropertyKey = any PropertyKey
public protocol PropertyKey: Hashable, CustomStringConvertible {
 associatedtype Value
}

public extension PropertyKey {
 static var description: String { "\(Self.self)" }
 var description: String { Self.description }
}

public typealias AnyResolvedKey = any ResolvedKey
public protocol ResolvedKey: PropertyKey {
 associatedtype Value
 associatedtype ResolvedValue
 static func resolveValue(_ value: Value?) -> ResolvedValue
 static func storeValue(_ value: ResolvedValue?) -> Value?
}

public extension ResolvedKey {
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

public protocol OptionalKey: PropertyKey {
 override associatedtype Value
 typealias ResolvedValue = Value?
}

public extension OptionalKey {
 static func resolveValue(_ value: Value?) -> Value? { value }
 static func storeValue(_ value: ResolvedValue?) -> Value? { value ?? nil }
}

public protocol DefaultKey: ResolvedKey where ResolvedValue == Value {
 override associatedtype ResolvedValue = Value
 static var defaultValue: Value { get }
}

public extension DefaultKey {
 static func resolveValue(_ value: Value?) -> ResolvedValue { defaultValue }
 static func storeValue(_ value: ResolvedValue?) -> Value? {
  value ?? defaultValue
 }
}

public extension DefaultKey where Value: Infallible {
 static var defaultValue: Value { Value.defaultValue }
}

public protocol IntBoolKey: ResolvedKey {
 override associatedtype Value = Int
 override associatedtype ResolvedValue = Bool
}

public extension IntBoolKey {
 static func resolveValue(_ value: Int?) -> Bool {
  guard let value else { return false }
  return value < 1 ? false : true
 }

 static func storeValue(_ value: Bool?) -> Int? {
  guard let value else { return .zero }
  return value ? 1 : .zero
 }
}

public protocol DoubleDateKey: ResolvedKey {
 override associatedtype Value = Double
 override associatedtype ResolvedValue = Date?
}

public extension DoubleDateKey {
 static func resolveValue(_ value: Double?) -> Date? {
  guard let value else { return nil }
  return Date(timeIntervalSinceReferenceDate: value)
 }

 static func storeValue(_ value: Date??) -> Double? {
  guard let value else { return nil }
  return value?.timeIntervalSinceReferenceDate
 }
}

#if canImport(Combine)
 /// A key useful for storing auto codable values. Usually, within a defaults
 /// protocol because it can provide uniform access to values
 /// - Note: Using this allows data of all types to use the same key because the
 /// stored value is data and the resolved value is the structure
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol AutoCodableKey: ResolvedKey
 where ResolvedValue: AutoCodable {
  override associatedtype Value = Data
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension DecodingError.Context {
  static var missingData: Self {
   Self(codingPath: .empty, debugDescription: "Data was missing")
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoCodableKey {
  static func storeValue(_ value: ResolvedValue?) -> Data? {
   guard let value else { return nil }
   do { return try ResolvedValue.encoder.encode(value) }
   catch {
    fatalError(error.localizedDescription)
   }
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoCodableKey where ResolvedValue: Infallible {
  static func resolveValue(_ data: Data?) -> ResolvedValue {
   do {
    guard let data else {
     throw DecodingError.valueNotFound(ResolvedValue.self, .missingData)
    }
    return try ResolvedValue.decoder.decode(ResolvedValue.self, from: data)
   } catch {
    print(error.localizedDescription)
    return .defaultValue
   }
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoCodableKey where ResolvedValue: ExpressibleByNilLiteral {
  static func resolveValue(_ data: Data?) -> ResolvedValue {
   do {
    guard let data else {
     throw DecodingError.valueNotFound(ResolvedValue.self, .missingData)
    }
    return try ResolvedValue.decoder.decode(ResolvedValue.self, from: data)
   } catch {
    print(error.localizedDescription)
    return nil
   }
  }
 }

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AutoCodable where Self: AutoCodableKey, Self: Infallible {
 public typealias ResolvedValue = Self
}


 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol AutoCodableArrayKey: ResolvedKey where Value == [Data] {
  associatedtype Element: AutoCodable
  override associatedtype ResolvedValue = [Element]
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoCodableArrayKey {
  static func storeValue(_ values: [Element]?) -> [Data]? {
   guard let values else { return nil }
   do {
    return try values.map { try Element.encoder.encode($0) }
   } catch {
    fatalError(error.localizedDescription)
   }
  }

  static func resolveValue(_ data: [Data]?) -> [Element] {
   do {
    guard let data else {
     throw DecodingError.valueNotFound(ResolvedValue.self, .missingData)
    }
    return try data.map {
     try Element.decoder.decode(Element.self, from: $0)
    }
   } catch {
    print(error.localizedDescription)
    return .empty
   }
  }
 }

#elseif canImport(OpenCombine)
#endif
