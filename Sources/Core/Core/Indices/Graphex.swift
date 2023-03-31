protocol RecursiveIndex: Comparable & Equatable where
Base: ExpressibleByArrayLiteral, Base.Index: Hashable & Comparable {
 associatedtype Base: MutableCollection
 var offset: Int { get set }
 var index: Base.Index { get set }
}

extension RecursiveIndex {
 static func < (lhs: Self, rhs: Self) -> Bool {
  lhs.offset < rhs.offset && lhs.index < rhs.index
 }

 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.offset == rhs.offset && lhs.index == rhs.index
 }
}

protocol RecursiveValue {
 associatedtype Next: RecursiveValue
 var next: Next? { get }
}

protocol ReflectiveValue {
 associatedtype Previous: RecursiveValue
 var previous: Previous? { get }
}

/// A recursive index that stores a value
protocol IndexicalValue:
Equatable & Comparable, RecursiveValue, ReflectiveValue, RecursiveIndex {
 typealias Element = Self
 typealias Value = Base.Element
 var base: Base { get set }
 var value: Value { get set }
 var elements: [Self] { get set }
 var start: Self { get set }
 var previous: Self? { get set }
 var next: Self? { get set }
 var end: Self? { get set }
 init()
}

/// Indexical value with storage for rebasing elements
protocol GraphicalIndex: IndexicalValue {
 var elements: [Self] { get nonmutating set }
 var base: Base { get nonmutating set }
 var value: Value { get nonmutating set }
 var start: Self { get nonmutating set }
 init()
}

extension GraphicalIndex {
 @inlinable static var empty: Self { Self() }
 static func < (lhs: Self, rhs: Self) -> Bool {
  lhs.offset < rhs.offset && lhs.index < rhs.index
 }

 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.offset == rhs.offset && lhs.index == rhs.index
 }
}

struct Graphex<Base>: GraphicalIndex where
 Base: RangeReplaceableCollection &
 MutableCollection & BidirectionalCollection &
 ExpressibleByArrayLiteral & ExpressibleAsEmpty,
 Base.Index: Hashable & Comparable & AtomicValue & Infallible {
 // - MARK: Starting properties
 init() {}
 @DefaultAtomic var index: Base.Index
 @DefaultAtomic var endIndex: Base.Index
 var _base: UnsafeMutableRawBufferPointer?
 @inlinable var base: Base {
  unsafeAddress {
   UnsafePointer(
    _base.unsafelyUnwrapped
     .assumingMemoryBound(to: Base.self).baseAddress.unsafelyUnwrapped
   )
  }
  nonmutating unsafeMutableAddress {
   _base.unsafelyUnwrapped
    .assumingMemoryBound(to: Base.self).baseAddress.unsafelyUnwrapped
  }
 }

 @inlinable var value: Value {
  unsafeAddress { withUnsafePointer(to: base[index]) { $0 } }
  nonmutating unsafeMutableAddress {
   withUnsafeMutablePointer(to: &base[index]) { $0 }
  }
 }

 var _elements: UnsafeMutableRawBufferPointer?
 @inlinable var elements: [Self] {
  unsafeAddress {
   UnsafePointer(
    _elements.unsafelyUnwrapped
     .assumingMemoryBound(to: [Self].self).baseAddress.unsafelyUnwrapped
   )
  }
  nonmutating unsafeMutableAddress {
   _elements.unsafelyUnwrapped
    .assumingMemoryBound(to: [Self].self).baseAddress.unsafelyUnwrapped
  }
 }

 var position: Int = .zero
 @DefaultAtomic var offset: Int
 @DefaultAtomic var _start: Int
 @inlinable var start: Self {
  unsafeAddress { withUnsafePointer(to: elements[_start]) { $0 } }
  nonmutating unsafeMutableAddress {
   withUnsafeMutablePointer(to: &elements[_start]) { $0 }
  }
 }
}

extension Graphex {
 var elementRange: Range<Int> { position ..< (position + offset) }
 var baseRange: Range<Base.Index> { index ..< endIndex }
 @inlinable var previousOffset: Int { position - 1 }
 @inlinable var nextOffset: Int { position + 1 }

 @inlinable var next: Self? {
  get {
   guard nextOffset < elements.endIndex else { return nil }
   return elements[nextOffset]
  }
  nonmutating set {
   precondition(nextOffset < elements.endIndex)
   guard let newValue else { return }
   elements[nextOffset] = newValue
  }
 }

 var previous: Self? {
  get {
   guard position > elements.startIndex else { return start }
   return elements[previousOffset]
  }
  nonmutating set {
   precondition(position > elements.startIndex)
   guard let newValue else { return }
   elements[previousOffset] = newValue
  }
 }

 var end: Self? {
  get {
   guard elements.count > 1 else { return nil }
   return elements.last.unsafelyUnwrapped
  }
  nonmutating set {
   precondition(!elements.isEmpty)
   guard let newValue else { return }
   elements[elements.endIndex - 1] = newValue
  }
 }

 @inlinable func step(
  _ content: @escaping (Self) -> Value?
 ) {
  if let newValue = content(elements[position]) { value = newValue }
 }

 @inlinable static func initiate(
  with base: Base,
  values: inout [Base],
  elements: inout [[Self]],
  offset: Int
 ) {
  values.append(base)
  elements.append([.empty])
  elements[offset][0]._base = withUnsafeMutableBytes(of: &values[offset]) { $0 }
  elements[offset][0]._elements =
   withUnsafeMutableBytes(of: &elements[offset]) { $0 }
  elements[offset][0].endIndex = base.endIndex
  elements[offset][0].offset = base.count
 }

 /// Creates a start element and new set of values pertaining to the
 /// start index
 @inlinable func rebase(
  _ base: Base,
  _ content: @escaping (Self) -> Value?
 ) {
  offset = base.count
  endIndex = base.index(index, offsetBy: offset)

  for (offset, element) in base.enumerated() {
   elements.append(.next(element, at: offset, with: self))

   let index = elements.endIndex - 1
   if let newValue = content(elements[index]) {
    elements[index].value = newValue
   }
  }
 }

 init(next value: Value, at offset: Int, with start: Self) {
  self._base = start._base
  self._elements = start._elements

  self.offset = offset
  self.index = base.endIndex
  self.endIndex = base.endIndex
  self.position = elements.endIndex
  self._start = start.position

  base.append(value)
 }

 @inlinable static func next(
  _ value: Value, at offset: Int, with start: Self
 ) -> Self {
  Self(next: value, at: offset, with: start)
 }
}

extension Graphex: Hashable {
 public func hash(into hasher: inout Hasher) {
  hasher.combine(_base?.baseAddress)
  hasher.combine(index)
 }
}

// MARK: - Indexer Protocol for storing indexing indexical values
protocol Indexer
where Base.Index: Equatable & Comparable, Element.Base == Base {
 associatedtype Base: MutableCollection & ExpressibleByArrayLiteral
 associatedtype Element: IndexicalValue
 typealias Value = Base.Element
 var index: Int { get }
 /// The return function used to store a mutated `Value`
 func callAsFunction(_ element: Element) -> Value?
}
