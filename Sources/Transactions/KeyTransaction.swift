public struct KeyTransaction
<Key: Sendable, B: Transactional>: Transactional {
 public init(source: Key, target: B? = nil) {
  self.source = source
  self.target = target
 }

 public let source: Key
 public var target: B?
}

public extension KeyTransaction {
 init(_ value: Key) {
  self.source = value
 }
}

public extension Transactional {
 static func + <B: Transactional>(lhs: Self, rhs: B) -> KeyTransaction<Self, B> {
  KeyTransaction(source: lhs, target: rhs)
 }
}

extension KeyTransaction: Equatable where Key: Equatable, B: Equatable {
 public static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.source == rhs.source && lhs.target == rhs.target
 }
}

extension KeyTransaction: Hashable where Key: Hashable, B: Hashable {
 public func hash(into hasher: inout Hasher) {
  hasher.combine(source)
  hasher.combine(target)
 }
}

// extension String: Transactional {
// public var source: Self { self }
// public var target: Self? {
//  get { self }
//  mutating set {
//   if let newValue { self = newValue } else { self = .empty }
//  }
// }
// }
