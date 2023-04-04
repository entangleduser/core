import Atomics
@propertyWrapper
struct UnsafeLockedPointer<Base: RangeReplaceableCollection>
where Base.Index: Hashable & Comparable & AtomicValue & Infallible,
Base.Index.AtomicRepresentation.Value == Base.Index {
 internal init(pointer: UnsafeMutablePointer<Base>? = nil, index: Index) {
  self.pointer = pointer
  self.index = index
 }

 typealias Index = Base.Index
 typealias Element = Base.Element
 var pointer: UnsafeMutablePointer<Base>!
 @DefaultAtomic var index: Index

 @inlinable var projectedValue: Base {
  unsafeAddress { UnsafePointer(pointer) }
  nonmutating unsafeMutableAddress { pointer }
 }

 @inlinable var wrappedValue: Element {
  unsafeAddress { withUnsafePointer(to: projectedValue[index]) { $0 } }
  nonmutating unsafeMutableAddress {
   UnsafeMutablePointer(
    mutating:
    withUnsafePointer(to: projectedValue[index]) { $0 }
   )
  }
 }
}

extension UnsafeLockedPointer: Equatable {
 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.pointer == rhs.pointer && lhs.index == rhs.index
 }
}

func withUnsafeLockedPointer<A: RangeReplaceableCollection, Result>(
 to values: inout A,
 with index: A.Index = .defaultValue,
 _ result: @escaping (UnsafeLockedPointer<A>) -> Result
) -> Result where A.Index: Hashable {
 result(
  UnsafeLockedPointer<A>(
   pointer: withUnsafeMutablePointer(to: &values) { $0 },
   index: index
  )
 )
}

extension UnsafeLockedPointer {
 init(contentsOf base: Base, to other: inout Base) {
  let index = other.endIndex
  other.append(contentsOf: base)
  self.init(pointer: withUnsafeMutablePointer(to: &other) { $0 }, index: index)
 }

 @inlinable static func appending(
  contentsOf base: Base,
  to other: inout Base
 ) -> Self {
  Self(contentsOf: base, to: &other)
 }

 init(_ element: Element, to other: inout Base) {
  let index = other.endIndex
  other.append(element)
  self.init(pointer: withUnsafeMutablePointer(to: &other) { $0 }, index: index)
 }

 @inlinable static func appending(
  _ element: Element,
  to other: inout Base
 ) -> Self {
  Self(element, to: &other)
 }

 init(aligning values: inout Base, to index: Index) {
  self.init(
   pointer: withUnsafeMutablePointer(to: &values) { $0 }, index: index
  )
 }

 @inlinable static func aligning(_ other: inout Base, to index: Index) -> Self {
  Self(aligning: &other, to: index)
 }

 @inlinable static func aligning(_ other: Self, to index: Index) -> Self {
  Self(aligning: &other.projectedValue, to: index)
 }
}
