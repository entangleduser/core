/// The structured cache for ``Object``
/// All modifiers and values associated with an object should be resolved before storing
/// into an indexed reflection of the modified object, because the builder can't change
/// this during runtime but is able to a pointer to the actual modified object
import Atomics

struct Parallel<A: MutableCollection>
where A: ExpressibleByArrayLiteral, A.Index: Equatable & Comparable {
 let storage: Storage
}

extension Parallel {
 struct Index: Comparable, Equatable {
  static var start: Self { Self(offset: A.empty.startIndex) }
  static func start(_ base: A) -> Self { Self(offset: base.startIndex) }
  // The index of elements by order
  var index: Int = .zero
  // The depth or order of group elements in line
  // Something that represents direct inheritence could be used instead of
  // simple variadic elements
  var inset: Int = .zero

  var offset: A.Index
  // The index of values by order
  var exponent: Int = .zero

  /// ``Addition`` operator, indicates an addition to the exponent value of an index
  static func *= (lhs: inout Self, offset: Int) { lhs.exponent += 1 }
//   /// ``Inset`` operator, increases the linear position of an index
//  static func += (index: inout Self, offset: Int) { index.linear += offset }
  /// ``Advance`` operator, increases the linear position of an index
  static func += (lhs: inout Self, offset: Int) { lhs.index += offset }
  /// ``Increase`` olhsperator, must take in a base collection for comparison
  static func >= (lhs: inout Self, base: A) {
   lhs.offset = base.index(after: lhs.offset)
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
   lhs.index < rhs.index &&
    lhs.inset < rhs.inset &&
    lhs.offset < rhs.offset &&
    lhs.exponent < rhs.exponent
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
   lhs.index == rhs.index &&
    lhs.inset == rhs.inset &&
    lhs.offset == rhs.offset &&
    lhs.exponent == rhs.exponent
  }

  static func ~= (lhs: Self, rhs: Self) -> Bool { lhs.exponent == rhs.exponent }
 }
}

extension Parallel: Sequence, IteratorProtocol {
 typealias Iterator = Self
 @inlinable var count: Int {
  elements.reduce(into: .zero) {
   switch $1 {
   case let .elements(other): $0 += other.count
   case let .variadic(other): $0 += other.count
   case .element: $0 += 1
   }
  }
 }

 @inlinable var startIndex: Index { .start }
 @inlinable var endIndex: Index {
  switch elements.last {
  case let .elements(other):
   return Index(
    index: elements.endIndex, offset: other.endIndex, exponent: count
   )
  //   case let .variadic(other):
  //    let otherIndex = other.endIndex
  //    return Index(
  //     index: otherIndex.index, offset: otherIndex.offset, exponent: self.count
  //    )
  default:
   return Index(
    index: elements.endIndex,
    offset: startIndex.offset, exponent: count
   )
  }
 }

 func next() -> A.Element? {
  guard index < endIndex else {
   index = .start
   return nil
  }
  defer { self.index = self.index(after: index) }
  return self[index]
 }

 @inlinable var isEmpty: Bool { elements.isEmpty }
}

extension Parallel: Collection {
 func index(after i: Index) -> Index {
  precondition(i < endIndex)
  switch elements[i.index] {
  case .variadic: fatalError() // return other.index(after: i)
  case let .elements(other):
   guard i.offset < other.index(other.endIndex, offsetBy: -1) else {
    return Index(
     index: i.index + 1, offset: startIndex.offset, exponent: i.exponent + 1
    )
   }
   if i.offset == other.startIndex {
    return Index(
     index: i.index,
     offset: other.index(i.offset, offsetBy: 1), exponent: i.exponent + 1
    )
   } else {
    return Index(
     index: i.index,
     offset: other.index(i.offset, offsetBy: 1), exponent: i.exponent + 1
    )
   }

  case .element:
   return Index(
    index: i.index + 1, offset: startIndex.offset, exponent: i.exponent + 1
   )
  }
 }
}

extension Parallel: BidirectionalCollection where A: BidirectionalCollection {
 func index(before i: Index) -> Index {
  precondition(i.index > elements.startIndex)
  switch elements[i.index] {
  case .variadic: fatalError() // return other.index(before: i)
  case let .elements(other):
   return Index(
    index: i.index, offset: other.index(before: i.offset), exponent: i.exponent - 1
   )
  case .element:
   return Index(
    index: i.index - 1, offset: startIndex.offset, exponent: i.exponent - 1
   )
  }
 }
}

extension Parallel: MutableCollection where A: MutableCollection {
 subscript(position: Index) -> A.Element {
  get {
   precondition(position < endIndex)
   switch elements[position.index] {
   case .variadic: fatalError() // return other[position]
   case let .elements(other):
    guard position.offset < other.endIndex else {
     return self[index(after: position)]
    }
    return other[position.offset]
   case let .element(other): return other
   }
  }
  set {
   precondition(position.index < elements.endIndex)
   switch elements[position.index] {
   case .variadic: fatalError()
//     other[Index(offset: position.offset, exponent: position.exponent)] = newValue
//     self.elements[position.index] = .variadic(other)
   case var .elements(other):
    if other.count > 1 {
//      other.remove(at: position.offset)
//      other.insert(newValue, at: position.offset)
     other[position.offset] = newValue
     elements[position.index] = .elements(other)
    } else {
     precondition(position.offset < other.endIndex)
     elements[position.index] = .element(newValue)
    }
   case .element: elements[position.index] = .element(newValue)
   }
  }
 }
}

extension Parallel: RangeReplaceableCollection where A: RangeReplaceableCollection {
 init(elements: UnsafeMutableRawBufferPointer, index: UnsafeMutablePointer<Index>) {
  self.storage = .init(elements: elements, index: index)
 }

 init(_ elements: [Elements.Element] = .empty) {
  var elements = elements
  var index: Index = .start
  self.init(
   elements: withUnsafeMutableBytes(of: &elements) { $0 },
   index: &index
  )
 }

 init() { self.init(.empty) }

 func add(_ newElement: Elements.Element) {
  elements.append(newElement)
 }

 func replaceSubrange<C>(_ range: Range<Index>, with: C)
 where C: Collection, Self.Element == C.Element {
  fatalError()
 }

 subscript(bounds: Range<Index>) -> Self.SubSequence {
  get { fatalError() }
  set {}
 }
}

// extension Parallel: AsyncSequence {
// typealias Element = A.Element
// typealias AsyncIterator = Self
// func next() async -> A.Element? {
//  fatalError()
// }
//
// func makeAsyncIterator() -> Self { self }
// }

extension Parallel {
 @dynamicMemberLookup
 struct Elements {
  @inlinable subscript<Value>(
   dynamicMember keyPath: KeyPath<[Element], Value>
  ) -> Value { self.elements[keyPath: keyPath] }

  enum Element {
   case variadic(Elements), elements(A), element(A.Element) // , self(Parallel)
  }

  var storage: Storage?
  var elements: [Element]

  init(_ elements: [Element]) {
   self.elements = elements
  }

  init(_ elements: Element...) {
   self.elements = elements
  }

  @inlinable var count: Int {
   self.elements.reduce(into: .zero) {
    switch $1 {
    case let .elements(other): $0 += other.count
    case let .variadic(other): $0 += other.count
    case .element: $0 += 1
    }
   }
  }
 }
}

extension Parallel.Elements: Sequence {
 @inlinable func makeIterator() -> Array<Element>.Iterator { elements.makeIterator() }
}

extension Parallel.Elements: Collection {
 @inlinable var startIndex: Int { elements.startIndex }
 @inlinable var endIndex: Int { elements.endIndex }
 @inlinable func index(after i: Int) -> Int {
  elements.index(after: i)
 }
}

extension Parallel.Elements: MutableCollection {
 @inlinable subscript(position: Int) -> Element {
  get { elements[position] }
  set { elements[position] = newValue }
 }
}

extension Parallel.Elements: RangeReplaceableCollection {
 init() { self.elements = .empty }

 internal mutating func append(_ newElement: Element) {
  elements.append(newElement)
 }

 func replaceSubrange<C>(_ range: Range<Index>, with: C)
 where C: Collection, Self.Element == C.Element {
  fatalError()
 }

 subscript(bounds: Range<Index>) -> Self.SubSequence {
  get { fatalError() }
  set {}
 }
}

extension Parallel {
 struct Storage {
  init(elements: UnsafeMutableRawBufferPointer, index: UnsafeMutablePointer<Index>) {
   self.__elements = elements
   self.__index = ManagedAtomic(index)
  }

  let __index: ManagedAtomic<UnsafeMutablePointer<Index>>
  let __elements: UnsafeMutableRawBufferPointer
 }

 @inlinable var _index: UnsafeMutablePointer<Index> {
  storage.__index.load(ordering: .relaxed)
 }

 var index: Index {
  @inlinable unsafeAddress { UnsafePointer(self._index) }
  @inlinable nonmutating unsafeMutableAddress { self._index }
 }

 @inlinable var _elements: UnsafeMutableBufferPointer<Elements> {
  storage.__elements.bindMemory(to: Elements.self)
 }

 var elements: Elements {
  @inlinable unsafeAddress { UnsafePointer(self._elements.baseAddress.unsafelyUnwrapped) }
  @inlinable nonmutating unsafeMutableAddress { self._elements.baseAddress.unsafelyUnwrapped }
 }
}

extension Parallel {
 init(_ elements: inout Elements, _ index: inout Index) {
  self.storage = Storage(
   elements: withUnsafeMutableBytes(of: &elements) { $0 },
   index: &index
  )
 }

 @discardableResult
 init(
  _ elements: inout Elements,
  _ index: inout Index, callAsFunction: @escaping (Self) throws -> Void
 ) rethrows {
  self.init(&elements, &index)
  try callAsFunction(self)
 }
}

extension Parallel.Elements.Element: CustomStringConvertible {
 @inlinable var description: String {
  switch self {
  case let .variadic(elements): return String(describing: elements)
  case let .elements(elements): return String(describing: elements)
  case let .element(elements): return String(describing: elements)
  }
 }
}

extension Parallel.Index: Hashable where A.Index: Hashable {}
extension Parallel.Index: CustomStringConvertible {
 var description: String { "(\(index)|\(offset)|\(exponent))" }
}

extension Parallel.Elements.Element: Equatable where A: Equatable, A.Element: Equatable {
 static func == (lhs: Self, rhs: Self) -> Bool {
  switch (lhs, rhs) {
  case let (.variadic(lhs), .variadic(rhs)): return lhs == rhs
  case let (.elements(lhs), .elements(rhs)): return lhs == rhs
  case let (.element(lhs), .element(rhs)): return lhs == rhs
  default: return false
  }
 }
}

extension Parallel.Elements: Equatable where A: Equatable, A.Element: Equatable {
 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.elements == rhs.elements
 }
}

extension Parallel: Equatable where A: Equatable, A.Element: Equatable {
 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.elements == rhs.elements
 }
}

extension Parallel.Elements: ExpressibleByArrayLiteral {
 init(arrayLiteral values: Element...) {
  self.init(values)
 }
}

extension Parallel.Elements.Element: ExpressibleByArrayLiteral
where A: ExpressibleByArrayLiteral & RangeReplaceableCollection {
 init(arrayLiteral values: A.Element...) {
  self = .elements(A(values))
 }
}
