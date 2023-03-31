public struct KeyTransaction<Key: Sendable, Hashable, Target: Transactional>: Transactional {
 public let source: Key
 public var target: Target?
}

public extension KeyTransaction where Key: Identifiable {
 init(_ value: Key) {
  self.source = value
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
