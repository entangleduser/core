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
