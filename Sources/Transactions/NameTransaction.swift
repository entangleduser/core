public struct NameTransaction: Transactional {
 public init() {}
 public init(from prior: UniqueTag<String>, to agent: UniqueTag<String?>) {
  self._source = prior
  self._target = agent
 }

 @UniqueTag public var source: String
 @UniqueTag public var target: String?
}

public extension NameTransaction {
//  public init(
//   using identity: Self,
//   with target: String, targetID: UUID) {
//   self.init(from: identity.source, to: target)
//  }
//
//  public static func name(with target: String) -> Self {
//   Self(using: .name, with: target)
//  }
//
//  public static func fullName(with target: String) -> Self {
//   Self(using: .fullName, with: target)
//  }
//
 @inline(__always) var sender: String { source }
 @inline(__always) var reciever: String? { target }
}

public typealias UniqueNameTransaction = UUIDTransaction<NameTransaction>

public extension UUIDTransaction where B == NameTransaction {
//  static let name = Self(to: .name)
//  static let fullName = Self(to: .fullName)
 var sender: String? {
  get { target?.source }
  set {
   guard let newValue else { return }
   target?.source = newValue
  }
 }

 var reciever: String? {
  get { target?.target }
  set { target?.target = newValue }
 }
}

extension NameTransaction: CustomStringConvertible {
 public var description: String {
  """
  \(source.isEmpty ? .empty : "\(_source.description)")\
  \(target?.isEmpty == true ? .empty : "/\(_target.description)")
  """
 }
}

import struct Foundation.UUID
extension NameTransaction: LosslessStringConvertible {
 public init?(_ description: String) {
  let splits = description.split(separator: "/", omittingEmptySubsequences: true)
  guard splits.notEmpty else { return nil }
  let sourceUUID = String(splits[1])
  let targetUUID = String(splits[3])
  self._source =
   .init(
    String(splits[0]),
    UUID(uuidString: sourceUUID)!
   )
  self._target =
   .init(
    String(splits[2]),
    UUID(uuidString: targetUUID)!
   )
 }
}

extension NameTransaction: Codable {
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
