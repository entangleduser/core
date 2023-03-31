@_exported import Combine
import Foundation

/// An object that conforms to `AutoDecodable` & `AutoEncodable`.
public protocol AutoCodable:
 AutoDecodable & AutoEncodable
 where AutoDecoder.Input == Data, AutoDecoder.Input == AutoEncoder.Output {
 static var decoder: AutoDecoder { get }
 static var encoder: AutoEncoder { get }
}

/// An object with a static, top level decoder.
@available(macOS 10.15, iOS 13.0, *)
public protocol AutoDecodable: Codable {
 associatedtype AutoDecoder: TopLevelDecoder
 /// Decoder used for decoding a `AutoDecodable` object.
 static var decoder: AutoDecoder { get }
}

/// An object with a static, top level encoder.
@available(macOS 10.15, iOS 13.0, *)
public protocol AutoEncodable: Codable {
 associatedtype AutoEncoder: TopLevelEncoder
 /// Encoder used for encoding a `AutoEncodable` object.
 static var encoder: AutoEncoder { get }
}

@available(macOS 10.15, iOS 13.0, *)
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
