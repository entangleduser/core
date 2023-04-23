/// A tag that uses the protocol `LosslessStringConvertible` to
/// convert the description of an object into a value
@propertyWrapper
public struct Tag<A: LosslessStringConvertible>: Sendable, Hashable {
 public init() {}
 public var value: String?
 public var wrappedValue: A? {
  get { value == nil ? nil : A(value!) }
  set {
   guard let newValue else { return }
   value = newValue.description
  }
 }

 public var projectedValue: Self { self }
}

public extension Tag {
 init(_ string: String) { self.value = string }
 init(_ value: A) {
  self.value = value.description
 }

 init(wrappedValue: some LosslessStringConvertible) {
  self.value = wrappedValue.description
 }
}

extension Tag: Codable {
 public init(from decoder: Decoder) throws {
  let container = try decoder.singleValueContainer()
  if container.decodeNil() { self.init() }
  else { try self.init(container.decode(String.self)) }
 }

 public func encode(to encoder: Encoder) throws {
  var container = encoder.singleValueContainer()
  try container.encode(value)
 }
}

extension Tag: Transactional {
 public var source: Self { self }
}

@propertyWrapper
public struct KeyTag: Hashable, Sendable {
 public init() {}
 public var wrappedValue: Int?
 public var projectedValue: AnyHashable? {
  get { wrappedValue }
  set { wrappedValue = newValue?.hashValue }
 }
}

extension KeyTag: Codable {
 init(wrappedValue: Int?) { self.wrappedValue = wrappedValue }
 public init(from decoder: Decoder) throws {
  let container = try decoder.singleValueContainer()
  if container.decodeNil() { self.init() }
  else { try self.init(wrappedValue: container.decode(Int.self)) }
 }

 public func encode(to encoder: Encoder) throws {
  var container = encoder.singleValueContainer()
  try container.encode(wrappedValue)
 }
}

import Extensions
@propertyWrapper
public struct AssociatedTag: Hashable, Sendable {
 public init() {}
 public var wrappedValue: [Int: String] = .empty
 public var projectedValue: Self {
  get { self }
  set { self = newValue }
 }
 public subscript<B: LosslessStringConvertible>(
  _ key: some Hashable, as type: B.Type
 ) -> B? {
  get {
   guard let desc = wrappedValue[key.hashValue]?.description else { return nil }
   return B(desc)
  }
  set {
   if let newValue {
    wrappedValue[key.hashValue] = newValue.description
   } else {
    wrappedValue.removeValue(forKey: key.hashValue)
   }
  }
 }
 public subscript(_ key: some Hashable) -> String? {
  get { wrappedValue[key.hashValue] }
  set {
   if let newValue {
    wrappedValue[key.hashValue] = newValue
   } else {
    wrappedValue.removeValue(forKey: key.hashValue)
   }
  }
 }
}

extension AssociatedTag: Codable {
 init(wrappedValue: [Int: String]) { self.wrappedValue = wrappedValue }
 public init(from decoder: Decoder) throws {
  let container = try decoder.singleValueContainer()
  if container.decodeNil() { self.init() }
  else { try self.init(wrappedValue: container.decode([Int: String].self)) }
 }

 public func encode(to encoder: Encoder) throws {
  var container = encoder.singleValueContainer()
  try container.encode(wrappedValue)
 }
}
