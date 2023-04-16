@_exported import Extensions
public protocol Transactional: Sendable {
 associatedtype A: Sendable
 associatedtype B: Transactional
 /// The source member for a transaction
 var source: A { get }
 /// The target for a transaction, which can be `nil` if it's a simple id
 /// and the narrative is optional
 var target: B? { get set }
 /// - NOTE: Fail-only initializer for transactions because they require a source
 init(from source: A, to target: B?)
}

public extension Transactional where Self.A: Infallible {
 @_disfavoredOverload
 static var defaultValue: Self { Self(from: .defaultValue, to: nil) }
}

public extension Transactional {
 init(from source: A, to target: B?) {
  fatalError()
 }
}

public extension Transactional {
 func getPaths(for transaction: some Transactional) -> [String]? {
  var items: [String] = .empty
  if source is (any Transactional), source is LosslessStringConvertible {
   items.append("\(source)")
  }
  if let target {
   if target is LosslessStringConvertible { items.append("\(target)") }
   else if let next = target.getPaths(for: target) {
    items.append(contentsOf: next)
   }
  }
  if items.isEmpty { return nil }
  return items
 }

 var paths: [String]? { getPaths(for: self) }
 var path: String? { getPaths(for: self)?.joined(separator: "/") }
 var id: String? { getPaths(for: self)?.joined(separator: "-") }
}

extension String: Transactional {
 public init(from source: String, to target: String?) {
  self = source
 }

 public var source: Self { get { self } mutating set { self = newValue } }
 public var target: Self? {
  get { self == .empty ? String?.none : self }
  mutating set { self = newValue ?? .empty }
 }
}

import Foundation
extension UUID: Transactional {
 public init(from source: UUID, to target: UUID?) {
  self = source
 }

 public var source: Self { get { self } mutating set { self = newValue } }
 public var target: Self? {
  get { self }
  mutating set { self = newValue ?? .defaultValue }
 }
}

extension Optional: CustomStringConvertible where Wrapped: CustomStringConvertible {
 public var description: String { self?.description ?? .empty }
}

extension Optional: LosslessStringConvertible where Wrapped: LosslessStringConvertible {
 public var description: String { self?.description ?? .empty }
 public init?(_ description: String) {
  guard let wrapped = Wrapped(description) else { return nil }
  self = .some(wrapped)
 }
}

extension Never: Transactional {
 public static var defaultValue: Never { fatalError() }
 public var source: Never { fatalError() }
 public var target: Never? { get { fatalError() } set {} }
}

public extension Transactional where B == Never {
 var target: Never? {
  get { nil }
  set(newValue) {}
 }
}

// extension Transactional
// where A: LosslessStringConvertible, B: LosslessStringConvertible {
// public init(from decoder: Decoder) throws {
//  var container = try decoder.unkeyedContainer()
//  if let source = try A(container.decode(String.self)),
//     let target = try B(container.decode(String.self)) {
//   self.init(from: source, to: target)
//  }
//  self.init(fro)
// }
// public func encode(to encoder: Encoder) throws {
//  var container = encoder.unkeyedContainer()
//  try container.encode(self.source.description)
//  try container.encode(self.target.description)
// }
// }
