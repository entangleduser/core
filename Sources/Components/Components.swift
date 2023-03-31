@_exported import Core
@_exported import Numerics
@_exported import Extensions

/// A functional element that can be represented as a deterministic value
public protocol Expressible: Sendable, Infallible {
 init()
}

public extension Expressible {
 static var defaultValue: Self { Self() }
}

// MARK: Symbolic types

/// A visible component that can be easily read and written to memory
public protocol Symbolic:
 Expressible,
 Hashable,
 // StringProtocol,
 RawRepresentable,
 ExpressibleByNilLiteral,
 ExpressibleByFloatLiteral,
 ExpressibleByIntegerLiteral,
 ExpressibleByStringLiteral
 where RawValue == String {
 var rawValue: String { get mutating set }
 init(rawValue: String)
}

public extension Symbolic {
 static var defaultValue: Self { Self() }
 init(nilLiteral: ()) { self.init() }
 init(rawValue: String) {
  self.init()
  self.rawValue = rawValue
 }

 init(_ rawValue: String) {
  self.init()
  self.rawValue = rawValue
 }

 init(stringLiteral string: String) { self.init(rawValue: string) }
 init(integerLiteral int: Int) { self.init(rawValue: int.description) }
 init(floatLiteral double: Double) { self.init(rawValue: double.description) }

 var description: String { String(describing: rawValue) }
 func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
}

public extension Symbolic {
 var utf8: String.UTF8View { rawValue.utf8 }
 var utf16: String.UTF16View { rawValue.utf16 }
 var unicodeScalars: String.UnicodeScalarView { rawValue.unicodeScalars }
 func hasPrefix(_ prefix: String) -> Bool { rawValue.hasPrefix(prefix) }
 func hasSuffix(_ suffix: String) -> Bool { rawValue.hasSuffix(suffix) }
 func lowercased() -> String { rawValue.lowercased() }
 func uppercased() -> String { rawValue.uppercased() }
 init<Encoding>(
  decoding codeUnits: some Collection<Encoding.CodeUnit>, as sourceEncoding: Encoding.Type
 ) where Encoding: _UnicodeEncoding {
  self.init(rawValue: String(decoding: codeUnits, as: sourceEncoding))
 }

 init(cString nullTerminatedUTF8: UnsafePointer<CChar>) {
  self.init(rawValue: String(cString: nullTerminatedUTF8))
 }

 init<Encoding>(
  decodingCString nullTerminatedCodeUnits: UnsafePointer<Encoding.CodeUnit>,
  as sourceEncoding: Encoding.Type
 ) where Encoding: _UnicodeEncoding {
  self.init(
   rawValue: String(decodingCString: nullTerminatedCodeUnits, as: sourceEncoding)
  )
 }

 func withCString<Result>(
  _ body: (UnsafePointer<CChar>
  ) throws -> Result) rethrows -> Result {
  try rawValue.withCString(body)
 }

 func withCString<Result, Encoding>(
  encodedAs targetEncoding: Encoding.Type,
  _ body: (UnsafePointer<Encoding.CodeUnit>
  ) throws -> Result
 ) rethrows -> Result where Encoding: _UnicodeEncoding {
  try rawValue.withCString(encodedAs: targetEncoding, body)
 }
}

public extension Symbolic {
 func index(before i: String.Index) -> String.Index {
  rawValue.index(before: i)
 }

 func index(after i: String.Index) -> String.Index {
  rawValue.index(after: i)
 }

 var startIndex: String.Index { rawValue.startIndex }
 var endIndex: String.Index { rawValue.endIndex }
 mutating func write(_ string: String) {
  var value = rawValue
  value.write(string)
  self = Self(value)
 }

 func write(to target: inout some TextOutputStream) {
  rawValue.write(to: &target)
 }

 subscript(position: String.Index) -> Character {
  get { rawValue[position] }
  mutating set {
   var value = rawValue
   value.replaceSubrange(
    position ..< position, with: [newValue]
   )
   self = Self(value)
  }
 }

// subscript(bounds: Range<Index>) -> Substring {
//  get { rawValue[bounds] }
//  mutating set {
//   var value = rawValue
//   value.replaceSubrange(bounds, with: newValue)
//   self = Self(value)
//  }
// }
}

// MARK: Default Types
extension String: Symbolic {
 public var rawValue: String {
  get { self }
  mutating set { self = newValue }
 }
}

// MARK: Value types

/// A transferable element that represents any value in an expressible context
public protocol Valueable:
 Composite, ExpressibleByIntegerLiteral, ExpressibleByNilLiteral where
 Exponent: ExpressibleByFloatLiteral & ExpressibleAsZero {
 /// This can be a pointer, static, or a dynamic value
 var component: Component { get set }
 /// This can be any element that determines difference in volume or scale
 var exponent: Exponent { get set }
}

public extension Valueable {
 static var defaultValue: Self { Self() }
 init(nilLiteral: ()) { self.init() }
 init(component: Component = .defaultValue, exponent: Exponent = .zero) {
  self.init()
  self.component = component
  self.exponent = exponent
 }

 init(integerLiteral value: Int) {
  self.init(exponent: Exponent(exactly: value)!)
 }

 static func * (lhs: Self, rhs: Self) -> Self {
  Self(exponent: lhs.exponent * rhs.exponent)
 }

 static prefix func + (x: Self) -> Self {
  Self(exponent: x.exponent)
 }

 static func + (lhs: Self, rhs: Self) -> Self {
  Self(exponent: lhs.exponent + rhs.exponent)
 }

 static func - (lhs: Self, rhs: Self) -> Self {
  Self(exponent: lhs.exponent - rhs.exponent)
 }

 static func *= (lhs: inout Self, rhs: Self) { lhs.exponent *= rhs.exponent }
 static func += (lhs: inout Self, rhs: Self) { lhs.exponent += rhs.exponent }
 static func -= (lhs: inout Self, rhs: Self) { lhs.exponent -= rhs.exponent }
 static func == (lhs: Self, rhs: Self) -> Bool { lhs.exponent == rhs.exponent }
 static func != (lhs: Self, rhs: Self) -> Bool { lhs.exponent != rhs.exponent }
}

public extension Valueable where Exponent: BinaryFloatingPoint {
 static func / (lhs: Self, rhs: Self) -> Self {
  Self(exponent: lhs.exponent / rhs.exponent)
 }

 static func /= (lhs: inout Self, rhs: Self) { lhs.exponent /= rhs.exponent }
}

public extension Valueable where Exponent: Comparable {
 static func < (lhs: Self, rhs: Self) -> Bool {
  lhs.exponent < rhs.exponent
 }

 static func > (lhs: Self, rhs: Self) -> Bool {
  lhs.exponent > rhs.exponent
 }

 static func <= (lhs: Self, rhs: Self) -> Bool {
  lhs.exponent <= rhs.exponent
 }

 static func >= (lhs: Self, rhs: Self) -> Bool {
  lhs.exponent >= rhs.exponent
 }
}

extension Int: Expressible {}
