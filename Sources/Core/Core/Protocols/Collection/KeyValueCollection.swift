/// A container for performing functions based on unique values.
public protocol KeyValueCollection: KeyValuable {
 typealias Base = [Key: Value]
 var _elements: Base { get nonmutating set }
}

public extension KeyValueCollection {
 @inlinable
 func contains(_ key: Key) -> Bool {
  _elements[key] != nil
 }

 @inlinable
 func contains(_: Value) -> Bool {
  _elements.keys.contains(where: { _elements[$0] != nil })
 }

 @inlinable
 subscript(_ key: Key) -> Value? {
  get { _elements[key] }
  nonmutating set { _elements[key] = newValue }
 }
}

// MARK: Conformance Helpers

public extension KeyValueCollection where Key == Int, Value: Hashable {
 @inlinable
 mutating func append(_ value: Value) {
  _elements[value.hashValue] = value
 }

 @inlinable
 mutating func append(_ values: [Value]) {
  values.forEach { self.append($0) }
 }

 init(_ values: [Base.Value]) {
  self.init()
  append(values)
 }

 init(arrayLiteral elements: Value...) {
  self.init(elements)
 }
}

public extension KeyValueCollection where Key == Value.ID, Value: Identifiable {
 @inlinable
 mutating func append(_ value: Value) {
  _elements[value.id] = value
 }
}
