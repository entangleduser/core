import class Atomics.ManagedAtomic
@dynamicMemberLookup
@propertyWrapper
public struct Value<Wrapped>: @unchecked Sendable, DynamicProperty {
 var _reference: UniqueReference<StaticPropertyStorage>.Weak?
 var _offset: ManagedAtomic<Int>?
 let get: () -> Wrapped, set: (Wrapped) -> Void

 public var wrappedValue: Wrapped {
  get { self.get() }
  nonmutating set {
   set(newValue)
   update()
  }
 }

 public var projectedValue: Value<Wrapped> { self }

 subscript<Value>(dynamicMember keyPath: WritableKeyPath<Wrapped, Value>
 ) -> Value {
  get { wrappedValue[keyPath: keyPath] }
  nonmutating set { wrappedValue[keyPath: keyPath] = newValue }
 }
}

extension Value: StaticProperty {}

public extension Value {
 init(wrappedValue: Wrapped) {
  self = .constant(wrappedValue)
 }

 init(get: @escaping () -> Wrapped, set: @escaping (Wrapped) -> Void) {
  self.get = get
  self.set = set
  // self.init(get: get, set: { value, _ in set(value) })
 }

// init(get: @escaping () -> Wrapped, set: @escaping (Wrapped, Transaction) -> ()) {
//  self.get = get
//  self.set = set
//  self.transaction = transaction
// }

 static func constant(_ value: Wrapped) -> Self {
  var value = value
  return Self(
   get: { value }, set: { value = $0 }
  )
 }
}

public extension Value where Wrapped: ExpressibleByNilLiteral {
 init() { self.init(wrappedValue: nil) }
}

// MARK: - Value Extensions
extension Value: Identifiable where Wrapped: Identifiable {
 public var id: Wrapped.ID { self.wrappedValue.id }
}

extension Value: CustomStringConvertible where Wrapped: CustomStringConvertible {
 public var description: String { self.wrappedValue.description }
}

extension Value: CustomDebugStringConvertible where Wrapped: CustomDebugStringConvertible {
 public var debugDescription: String { self.wrappedValue.debugDescription }
}

extension Value: Sequence where Wrapped: MutableCollection {
 public typealias Element = Value<Wrapped.Element>
 public typealias Iterator = IndexingIterator<Value<Wrapped>>
 public typealias SubSequence = Slice<Value<Wrapped>>
}

extension Value: Collection where Wrapped: MutableCollection {
 public typealias Index = Wrapped.Index
 public typealias Indices = Wrapped.Indices
 public var startIndex: Value<Wrapped>.Index { self.wrappedValue.startIndex }
 public var endIndex: Value<Wrapped>.Index { self.wrappedValue.endIndex }
 public var indices: Wrapped.Indices { self.wrappedValue.indices }

 public func index(after i: Value<Wrapped>.Index) -> Value<Wrapped>.Index {
  self.wrappedValue.index(after: i)
 }

 public func formIndex(after i: inout Value<Wrapped>.Index) {
  self.wrappedValue.formIndex(after: &i)
 }

 public subscript(position: Value<Wrapped>.Index) -> Value<Wrapped>.Element {
  Value<Wrapped.Element> {
   wrappedValue[position]
  } set: {
   wrappedValue[position] = $0
  }
 }
}

extension Value: BidirectionalCollection
where Wrapped: BidirectionalCollection, Wrapped: MutableCollection {
 public func index(before i: Value<Wrapped>.Index) -> Value<Wrapped>.Index {
  self.wrappedValue.index(before: i)
 }

 public func formIndex(before i: inout Value<Wrapped>.Index) {
  self.wrappedValue.formIndex(before: &i)
 }
}

extension Value: RandomAccessCollection
where Wrapped: MutableCollection, Wrapped: RandomAccessCollection {}

extension Value: Equatable where Wrapped: Equatable {
 public static func == (lhs: Value<Wrapped>, rhs: Value<Wrapped>) -> Bool {
  lhs.wrappedValue == rhs.wrappedValue
 }
}

extension Value: Infallible where Wrapped: Infallible {
 public static var defaultValue: Value<Wrapped> { .constant(.defaultValue) }
}
