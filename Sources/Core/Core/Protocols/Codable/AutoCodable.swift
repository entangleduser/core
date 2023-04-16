import struct Foundation.Data
import struct Foundation.URL
#if canImport(Combine)
 @_exported import Combine
 /// An object that conforms to `AutoDecodable` & `AutoEncodable`.
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol AutoCodable: AutoDecodable & AutoEncodable
 where AutoDecoder.Input == Data, AutoDecoder.Input == AutoEncoder.Output {
  static var decoder: AutoDecoder { get }
  static var encoder: AutoEncoder { get }
 }

 /// An object with a static, top level decoder.
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol AutoDecodable: Codable {
  associatedtype AutoDecoder: TopLevelDecoder
  /// Decoder used for decoding a `AutoDecodable` object.
  static var decoder: AutoDecoder { get }
 }

 /// An object with a static, top level encoder.
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol AutoEncodable: Codable {
  associatedtype AutoEncoder: TopLevelEncoder
  /// Encoder used for encoding a `AutoEncodable` object.
  static var encoder: AutoEncoder { get }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoEncodable {
  func encoded() throws -> AutoEncoder.Output {
   try Self.encoder.encode(self)
  }

  var data: AutoEncoder.Output? { try? encoded() }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 extension Optional: AutoEncodable where Wrapped: AutoEncodable {
  public static var encoder: Wrapped.AutoEncoder {
   Wrapped.encoder
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 extension Optional: AutoDecodable where Wrapped: AutoDecodable {
  public static var decoder: Wrapped.AutoDecoder {
   Wrapped.decoder
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 extension Optional: AutoCodable where Wrapped: AutoCodable {}

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoDecodable {
  init(_ input: AutoDecoder.Input) throws {
   self = try Self.decoder.decode(Self.self, from: input)
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoCodable {
  private var mirror: Mirror {
   Mirror(reflecting: self)
  }

  static var members: [String: String] {
   Dictionary(
    uniqueKeysWithValues:
    Mirror(reflecting: Self.self).children.map { label, _ in
     (label ?? .empty, String(describing: label))
    }
   )
  }

  var isEmpty: Bool { dictionary.isEmpty }
  var notEmpty: Bool { !isEmpty }
  var wrapped: Self? { isEmpty ? .none : self }
  var dictionary: [String: Any] {
   Dictionary(
    uniqueKeysWithValues:
    mirror.children.map { ($0.label!, $0.value) }
   )
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension TopLevelDecoder where Input == Data {
  func decode<A: Decodable>(
   contentOf url: URL,
   options: Data.ReadingOptions = .empty,
   _ type: A.Type
  ) throws -> A {
   try decode(type, from: Data(contentsOf: url, options: options))
  }
 }

 // MARK: Array Conformances
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 extension Array: AutoEncodable where Element: AutoEncodable {
  public static var encoder: Element.AutoEncoder { Element.encoder }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 extension Array: AutoDecodable where Element: AutoDecodable {
  public static var decoder: Element.AutoDecoder { Element.decoder }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 extension Array: AutoCodable where Element: AutoCodable {}

 // MARK: Self Conformances
 // TODO: Offer more nuanced control over encoders / decoders
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol StaticEncodable: AutoEncodable {
  static func encode(_ value: Self) throws -> Data
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol StaticDecodable: AutoDecodable {
  static func decode(_ data: Data) throws -> Self
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public typealias StaticCodable = StaticEncodable & StaticDecodable

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public struct StaticEncoder<A: StaticEncodable>: TopLevelEncoder {
  public init() {}
  public func encode(_ value: some Encodable) throws -> Data {
   try A.encode(value as! A)
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension StaticEncodable {
  static var encoder: StaticEncoder<Self> { StaticEncoder<Self>() }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public struct StaticDecoder<A: StaticDecodable>: TopLevelDecoder {
  public init() {}
  public func decode<T>(
   _ type: T.Type, from data: Data
  ) throws -> T where T: Decodable { try A.decode(data) as! T }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension StaticDecodable {
  static var decoder: StaticDecoder<Self> { StaticDecoder<Self>() }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoDecodable {
  func decode(_ data: AutoDecoder.Input) throws -> Self {
   try Self.decoder.decode(Self.self, from: data)
  }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension AutoEncodable {
  func encode(_ value: Self) throws -> AutoEncoder.Output { try value.encoded() }
 }
#else
 @_exported import OpenCombine
 /// An object that conforms to `AutoDecodable` & `AutoEncodable`.
 public protocol AutoCodable: AutoDecodable & AutoEncodable
 where AutoDecoder.Input == Data, AutoDecoder.Input == AutoEncoder.Output {
  static var decoder: AutoDecoder { get }
  static var encoder: AutoEncoder { get }
 }

 /// An object with a static, top level decoder.
 public protocol AutoDecodable: Codable {
  associatedtype AutoDecoder: TopLevelDecoder
  /// Decoder used for decoding a `AutoDecodable` object.
  static var decoder: AutoDecoder { get }
 }

 /// An object with a static, top level encoder.
 public protocol AutoEncodable: Codable {
  associatedtype AutoEncoder: TopLevelEncoder
  /// Encoder used for encoding a `AutoEncodable` object.
  static var encoder: AutoEncoder { get }
 }

 public extension AutoEncodable {
  func encoded() throws -> AutoEncoder.Output {
   try Self.encoder.encode(self)
  }

  var data: AutoEncoder.Output? { try? encoded() }
 }

 extension Optional: AutoEncodable where Wrapped: AutoEncodable {
  public static var encoder: Wrapped.AutoEncoder {
   Wrapped.encoder
  }
 }

 extension Optional: AutoDecodable where Wrapped: AutoDecodable {
  public static var decoder: Wrapped.AutoDecoder {
   Wrapped.decoder
  }
 }

 extension Optional: AutoCodable where Wrapped: AutoCodable {}

 public extension AutoDecodable {
  init(_ input: AutoDecoder.Input) throws {
   self = try Self.decoder.decode(Self.self, from: input)
  }
 }

 public extension AutoCodable {
  private var mirror: Mirror {
   Mirror(reflecting: self)
  }

  static var members: [String: String] {
   Dictionary(
    uniqueKeysWithValues:
    Mirror(reflecting: Self.self).children.map { label, _ in
     (label ?? .empty, String(describing: label))
    }
   )
  }

  var isEmpty: Bool { dictionary.isEmpty }
  var notEmpty: Bool { !isEmpty }
  var wrapped: Self? { isEmpty ? .none : self }
  var dictionary: [String: Any] {
   Dictionary(
    uniqueKeysWithValues:
    mirror.children.map { ($0.label!, $0.value) }
   )
  }
 }

 public extension TopLevelDecoder where Input == Data {
  func decode<A: Decodable>(
   contentOf url: URL,
   options: Data.ReadingOptions = .empty,
   _ type: A.Type
  ) throws -> A {
   try decode(type, from: Data(contentsOf: url, options: options))
  }
 }

 // MARK: Array Conformances
 extension Array: AutoEncodable where Element: AutoEncodable {
  public static var encoder: Element.AutoEncoder { Element.encoder }
 }

 extension Array: AutoDecodable where Element: AutoDecodable {
  public static var decoder: Element.AutoDecoder { Element.decoder }
 }

 extension Array: AutoCodable where Element: AutoCodable {}

 public protocol StaticEncodable: AutoEncodable {
  static func encode(_ value: Self) throws -> Data
 }

 public protocol StaticDecodable: AutoDecodable {
  static func decode(_ data: Data) throws -> Self
 }

 public typealias StaticCodable = StaticEncodable & StaticDecodable

 public struct StaticEncoder<A: StaticEncodable>: TopLevelEncoder {
  public init() {}
  public func encode(_ value: some Encodable) throws -> Data {
   try A.encode(value as! A)
  }
 }

 public extension StaticEncodable {
  static var encoder: StaticEncoder<Self> { StaticEncoder<Self>() }
 }

 public struct StaticDecoder<A: StaticDecodable>: TopLevelDecoder {
  public init() {}
  public func decode<T>(
   _ type: T.Type, from data: Data
  ) throws -> T where T: Decodable { try A.decode(data) as! T }
 }

 public extension StaticDecodable {
  static var decoder: StaticDecoder<Self> { StaticDecoder<Self>() }
 }

 public extension AutoDecodable {
  func decode(_ data: AutoDecoder.Input) throws -> Self {
   try Self.decoder.decode(Self.self, from: data)
  }
 }

 public extension AutoEncodable {
  func encode(_ value: Self) throws -> AutoEncoder.Output { try value.encoded() }
 }
#endif
