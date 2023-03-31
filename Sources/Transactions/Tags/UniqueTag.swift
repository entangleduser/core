import struct Foundation.UUID
@propertyWrapper
public struct UniqueTag
<Value: LosslessStringConvertible & Infallible>: Identifiable, Sendable, Hashable {
 public let id: UUID
 public var value: String
 public var wrappedValue: Value {
  get { Value(self.value) ?? .defaultValue }
  mutating set { self.value = newValue.description }
 }

 public init(wrappedValue: Value = .defaultValue, id: UUID = .defaultValue) {
  self.id = id
  self.value = wrappedValue.description
 }
}

public extension UniqueTag {
 init(_ value: Value, _ id: UUID) {
  self.id = id
  self.value = value.description
 }
}

extension UniqueTag: CustomStringConvertible {
 public var description: String {
  """
  \(self.value.isEmpty ? .empty : "\(self.value)")\
  /\(self.id.uuidString)
  """
 }
}

extension UniqueTag: LosslessStringConvertible {
 public init?(_ description: String) {
  guard let startIndex = description.firstIndex(of: "/"),
        let nextIndex =
        description.index(startIndex, offsetBy: 1, limitedBy: description.endIndex),
        let id = UUID(uuidString: String(description[nextIndex ..< description.endIndex]))
  else { return nil }
  self.id = id
  self.value = String(description[description.startIndex ..< startIndex])
 }
}

extension UniqueTag: Codable {
 enum Error: Swift.Error {
  case corruptData
 }

 public init(from decoder: Decoder) throws {
  let container = try decoder.singleValueContainer()
  if let finalized = try Self(container.decode(String.self)) {
   self = finalized
  } else {
   throw Error.corruptData
  }
 }

 public func encode(to encoder: Encoder) throws {
  var container = encoder.singleValueContainer()
  try container.encode(self.description)
 }
}
