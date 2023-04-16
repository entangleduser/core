import Atomics
public struct Peek<A: Collection>
where A: ExpressibleAsEmpty, A.Index: Equatable & Comparable {
 public let storage: Storage
}

extension Peek: Sequence, IteratorProtocol {
 public typealias Element = A.Element
 public typealias SubSequence = A.SubSequence
 public typealias Index = A.Index
 public typealias Iterator = Self
 public var count: Int { elements.count }
 @inlinable public var startIndex: Index { elements.startIndex }
 @inlinable public var endIndex: Index { elements.endIndex }
 public func validate(_ range: Range<Index>) -> Bool {
  range.lowerBound >= elements.startIndex
   && range.upperBound <= elements.endIndex
 }

 public func valid(_ range: Range<Index>) -> Range<Index> {
  (range.lowerBound >= elements.startIndex ? range.lowerBound :
   elements.startIndex) ..< (range.upperBound <= elements.endIndex ?
   range.upperBound : elements.endIndex)
 }

 public func makeIterator() -> Self { self }
// @inlinable public func index(_ i: Index, offsetBy offset: Int) -> Index {
//  self.elements.index(i, offsetBy: offset)
// }
//
// @inlinable public func index(
//  _ i: Index,
//  offsetBy offset: Int,
//  limitedBy limit: Index
// ) -> Index? {
//  self.elements.index(i, offsetBy: offset, limitedBy: limit)
// }

 public func next() -> Element? {
  guard index < endIndex else { return nil }
  defer { index = elements.index(after: index) }
  return elements[index]
 }
}

public extension Peek /*: Collection */ {
 @inlinable func index(after i: Index) -> Index { elements.index(after: i) }

 var nextIndex: Index? {
  guard index < elements.endIndex else { return nil }
  return elements.index(after: index)
 }
}

public extension Peek where A: RangeReplaceableCollection /*: MutableCollection */ {
 subscript(_ position: Index) -> Element {
  get { elements[position] }
  nonmutating set { self.elements.insert(newValue, at: position) }
 }

 var element: Element {
  get { elements[index] }
  nonmutating set { self.elements.insert(newValue, at: self.index) }
 }
}

public extension Peek where A: BidirectionalCollection {
 @inlinable func index(before i: Index) -> Index { elements.index(before: i) }
 @inlinable var lastValidIndex: Index {
  elements.index(before: elements.endIndex)
 }

 @inlinable func validate(_ i: Index) -> Bool {
  i < lastValidIndex && i >= startIndex
 }

 @inlinable func wrappedIndex(_ i: Index) -> Index? { validate(i) ? i : nil }
 @inlinable var wrappedIndex: Index? { wrappedIndex(index) }

 @inlinable func safeIndex(offsetBy i: Int = 0) -> Index {
  let idx = elements.index(index, offsetBy: i)
  return idx < startIndex ? startIndex :
   idx >= endIndex ? lastValidIndex : idx
 }

 @inline(__always) var safeIndex: Index { safeIndex() }

 var previousIndex: Index? {
  guard index > startIndex else { return nil }
  return elements.index(before: index)
 }
}

public extension Peek where A: RangeReplaceableCollection & BidirectionalCollection {
 @inlinable @discardableResult func remove(at i: Index) -> Element {
  defer { index = safeIndex }
  return elements.remove(at: i)
 }

 @inlinable func replace(_ newElement: Element, at index: Index) {
  defer { remove(at: index) }
  elements.insert(newElement, at: index)
 }

 @inlinable func replace(_ newElements: A, at index: Index) {
  defer { remove(at: index) }
  elements.insert(contentsOf: newElements, at: index)
 }

 internal var previousElement: Element? {
  get {
   guard let idx = previousIndex else { return nil }
   return elements[idx]
  }
  nonmutating set {
   guard let idx = previousIndex else { return }
   guard let newValue else {
    remove(at: idx)
    return
   }
   self[idx] = newValue
  }
 }
}

public extension Peek where A: RangeReplaceableCollection {
 @inlinable func replaceSubrange(
  _ subrange: Range<Index>, with newElements: A
 ) {
  elements.replaceSubrange(subrange, with: newElements)
 }

 @inlinable func replaceSubrange(
  _ subrange: Range<Index>, with newElements: [Element]
 ) {
  elements.replaceSubrange(subrange, with: newElements)
 }

 @inlinable func removeSubrange(_ bounds: Range<Index>) {
  elements.removeSubrange(bounds)
 }

 @inlinable func append(_ newElement: Element) {
  elements.append(newElement)
 }

 @inlinable func append<S>(contentsOf newElements: S)
 where S: Sequence, Self.Element == S.Element {
  elements.append(contentsOf: newElements)
 }

 @inlinable func insert(_ newElement: Element, at i: Index) {
  elements.insert(newElement, at: i)
 }

 @inlinable func insert(contentsOf newElements: A, at i: Index) {
  elements.insert(contentsOf: newElements, at: i)
 }

 @inlinable func removeAll(keepingCapacity keepCapacity: Bool = false) {
  elements.removeAll(keepingCapacity: keepCapacity)
 }

 var nextElement: Element? {
  get {
   guard let idx = nextIndex else { return nil }
   return elements[idx]
  }
  nonmutating set {
   guard let idx = nextIndex else { return }
   guard let newValue else {
    elements.remove(at: idx)
    return
   }
   self[idx] = newValue
  }
 }

 @inlinable subscript<R: RangeExpression>(range: R) -> SubSequence?
  where R.Bound == SubSequence.Index {
  get {
   // ?? range.relative(to: elements)
   elements[range as! Range<Index>]
  }
  nonmutating set {
   guard let newValue else {
    elements.removeSubrange(range)
    // index = safeIndex(offsetBy: range.relative(to: elements).endIndex.distance(to: index))
    return
   }
   elements.replaceSubrange(range, with: newValue)
   // index = range.relative(to: elements).endIndex
  }
 }

 internal var beforeRange: Range<Index>? {
  guard index > elements.startIndex else { return nil }
  return elements.startIndex ..< index
 }

 internal var afterRange: Range<Index>? {
  guard let idx = nextIndex else { return nil }
  return idx ..< elements.endIndex
 }

 internal var beforeElements: SubSequence? {
  get {
   guard let range = beforeRange else { return nil }
   return self[range]
  }
  nonmutating set {
   guard let range = beforeRange else { return }
   self[range] = newValue
  }
 }

 internal var afterElements: SubSequence? {
  get {
   guard let range = afterRange else { return nil }
   return self[range]
  }
  nonmutating set {
   guard let range = afterRange else { return }
   self[range] = newValue
  }
 }

 /// Advances to the next index of `element` or the `endIndex`
 func advance(to element: Element) -> Index? where Element: Equatable {
  guard let matchIndex = afterElements?.firstIndex(of: element) else {
   return nil
  }
  defer { self.index = elements.index(after: matchIndex) }
  return matchIndex
 }

 func advance(where true: @escaping (Element) throws -> Bool) rethrows -> Index? {
  guard let matchIndex = try afterElements?.firstIndex(where: `true`) else {
   return nil
  }
  defer { self.index = index(after: matchIndex) }
  return matchIndex
 }

 func resetIndex() { index = startIndex }
}

// func transformElements(
//  _ before: inout SubSequence?,
//  _ current: inout Element,
//  _ after: inout SubSequence?
// ) {
//  self.beforeElements = before
//  self.element = current
//  self.afterElements = after
// }
//
// func withTransform(
//  closure: @escaping
//  (_ before: inout SubSequence?, _ current: inout Element, _ after: inout SubSequence?)
//   throws -> ()
// ) rethrows {
//  try closure(&self.beforeElements, &self.element, &self.afterElements)
// }
//
// func stepTransform(
//  advanceBy _: Int = 1,
//  closure: @escaping
//  (_ before: inout SubSequence?, _ current: inout Element, _ after: inout SubSequence?)
//   throws -> ()
// ) rethrows {
//  try closure(&self.beforeElements, &self.element, &self.afterElements)
// }
// }

// public extension Peek {
//// func stride(
////  closure: @escaping
////  (_ before: inout SubSequence?, _ current: inout Element, _ after: inout SubSequence?)
////   throws -> ()
//// ) rethrows {
////  defer { index = startIndex }
////  repeat { try self.stepTransform(closure: closure) } while self.index < self.lastValidIndex
//// }
// }
//
public extension Peek
 where A: RangeReplaceableCollection & BidirectionalCollection,
 Element: Equatable,
 SubSequence: Equatable {
 subscript(
  sequence: SubSequence,
  limit: Index? = .none,
  max: Int? = .none
 ) -> [SubSequence] {
  guard !elements.isEmpty else { return .empty }
  var results = [SubSequence]()
  let first = sequence.first.unsafelyUnwrapped
  for element in self where element == first {
   let startIndex = elements.index(before: index)
   if let limit, limit == startIndex { break }
   guard
    let endIndex =
    elements.index(startIndex, offsetBy: sequence.count, limitedBy: endIndex)
   else { break }
   let range = startIndex ..< endIndex
   let slice = self[range]!
   if sequence == slice {
    if let max, results.count - 1 == max { break }
    results.append(slice)
    self.index = endIndex
   }
  }
  if limit != lastValidIndex, sequence.count == 1,
     elements[lastValidIndex] == first {
   results.append(self[index ... index]!)
  }
  index = startIndex
  return results
 }

 subscript(
  sequences: [SubSequence],
  limit: Index? = .none,
  max: Int? = .none
 ) -> [SubSequence] where Element: Equatable, SubSequence: Equatable {
  guard !sequences.isEmpty, !elements.isEmpty else { return .empty }
  if sequences.count == 1 {
   return self[sequences.first.unsafelyUnwrapped, limit, max]
  }
  var results = [SubSequence]()
  for element in self {
   let sequences = sequences.filter { $0.first == element }
   var newResults = [SubSequence]()
   var lastIndex: Index?
   defer { self.index = elements.startIndex }
   for sequence in sequences {
    let startIndex = elements.index(before: index)
    if let limit, limit == startIndex { break }
    guard
     let endIndex =
     elements.index(startIndex, offsetBy: sequence.count, limitedBy: endIndex)
    else { break }
    let range = startIndex ..< endIndex
    let slice = self[range]!
    if sequence == slice {
     newResults.append(slice)
     if lastIndex == nil {
      lastIndex = endIndex
     } else if endIndex > lastIndex.unsafelyUnwrapped {
      lastIndex = endIndex
     }
    }
   }
   if let lastIndex {
    for newResult in results {
     results.append(newResult)
     if let max, results.count == max { return results }
    }
    index = lastIndex
   }
  }
  if limit != lastValidIndex {
   let sequences = sequences.filter {
    $0.count == 1 && $0.first == elements[self.lastValidIndex]
   }
   if sequences.notEmpty {
    for _ in sequences { results.append(self[index ... index]!) }
   }
  }
  return results
 }

 subscript(condition: @escaping (Element) -> Bool) -> [SubSequence] {
  guard !elements.isEmpty else { return .empty }
  return elements.indices.compactMap {
   condition(elements[$0]) ? self[$0 ... $0] : nil
  }
 }

 subscript<S>(
  condition: @escaping (SubSequence) -> Bool,
  delimiters: S,
  limit: Index? = .none, max: Int? = .none
 ) -> [SubSequence]
  where S.Element == Element, S: SetAlgebra {
  guard !delimiters.isEmpty, !elements.isEmpty else { return .empty }
  var results = [SubSequence]()
  defer { self.index = startIndex }
  for element in self where !delimiters.contains(element) {
   let startIndex = elements.index(before: index)
   if let limit, limit == startIndex { break }
   let after = elements[startIndex ..< endIndex]
   let endIndex = after.firstIndex(where: { delimiters.contains($0) }) ?? endIndex
   let range = startIndex ..< endIndex
   let slice = self[range]!
   if condition(slice) {
    results.append(slice)
    if let max, results.count == max { return results }
    self.index = endIndex
   }
  }
  if limit != lastValidIndex, let after = afterElements, condition(after) {
   results.append(self[index ... index]!)
  }
  return results
 }

 subscript(
  lhs: SubSequence,
  rhs: SubSequence,
  range: Range<Index>? = .none,
  optional: Bool = false
 ) -> [SubSequence] where Element: Equatable, SubSequence: Equatable {
  guard !elements.isEmpty else { return .empty }
  let initialResults = self[lhs, range]
  guard initialResults.notEmpty else { return .empty }
  var results = [SubSequence]()
  for slice in initialResults {
   let newResults = self[rhs, slice.range.upperBound ..< elements.endIndex, 1]
   if let first = newResults.first {
    results.append(self[slice.range.lowerBound ..< first.range.upperBound]!)
   } else if optional {
    results.append(slice)
   }
  }
  return results
 }

 /* func matches(_ sequence: SubSequence, range) -> SubSequence? {
  guard elements.notEmpty, let after = afterElements else { return nil }
  for element in after where sequence.first == element {
  let startIndex = after.index(before: index)
  for element in self where element == first {
  let startIndex = index(before: index)
  if let limit = limit, limit == startIndex { break }
  guard
  let endIndex = index(startIndex, offsetBy: sequence.count, limitedBy: endIndex)
  else { break }
  let range = startIndex ..< endIndex
  let slice = self[range]!
  if sequence == slice {
  if let max = max, results.count - 1 == max { break }
  results.append(slice)
  self.index = endIndex
  }
  }
  if limit != lastValidIndex, sequence.count == 1,
  elements[lastValidIndex] == first {
  results.append(self[index ... index])
  }
  index = startIndex

  }
  } */
 subscript(
  pairs: [(lhs: SubSequence, rhs: SubSequence, optional: Bool)],
  range: Range<Index>? = .none, optional: Bool = false
 ) -> [SubSequence] where Element: Equatable, SubSequence: Equatable {
  guard !elements.isEmpty else { return .empty }
  var results = [SubSequence]()

  for element in self {
   for (lhs, rhs, optional) in pairs where lhs.first == element {
    let lastIndex = safeIndex(offsetBy: -1)
    defer { self.index = lastIndex }
    let newResults = self[lhs, rhs]
    if newResults.notEmpty {
     // results.append(newResults)
    } else if optional {
     results.append(lhs)
    }
   }
  }
  return results
 }

 subscript(
  sequence: SubSequence,
  range: Range<Index>?, max: Int? = .none
 ) -> [SubSequence] where Element: Equatable, SubSequence: Equatable {
  guard let range else { return self[sequence] }
  let bounds = valid(range)
  index = bounds.lowerBound
  return self[sequence, bounds.upperBound, max]
 }

 subscript(
  sequence: SubSequence,
  ranges: some Collection<Range<Index>>, max: Int? = .none
 ) -> [SubSequence]
  where Element: Equatable, SubSequence: Equatable {
  if ranges.count == 1 { return self[sequence, ranges.first.unsafelyUnwrapped, max] }
  return ranges.flatMap { self[sequence, $0, max] }
 }
}

// import struct Foundation.String
// import struct Foundation.CharacterSet
//
// public extension Peek where A == String {
// func matches(
//  _ condition: @escaping (SubSequence) -> Bool,
//  delimiters: CharacterSet,// = .whitespacesAndNewlines,
//  limit: Index? = .none, max: Int? = .none
// ) -> [SubSequence] {
//  guard self.elements.notEmpty else { return .empty }
//  var results = [SubSequence]()
//  for element in self
//   where !delimiters.contains(element.unicodeScalars.first.unsafelyUnwrapped) {
//   let startIndex = elements.index(before: index)
//   if let limit, limit == startIndex { break }
//   let after = elements[startIndex ..< elements.endIndex]
//   let endIndex =
//    after.firstIndex(
//     where: { delimiters.contains($0.unicodeScalars.first.unsafelyUnwrapped) }
//    ) ?? endIndex
//   let range = startIndex ..< endIndex
//   let slice = self[range].unsafelyUnwrapped
//   if condition(slice) {
//    if let max, results.count - 1 == max { break }
//    results.append(slice)
//    self.index = endIndex
//   }
//  }
//  if limit != self.lastValidIndex,
//     let afterElements, condition(afterElements) {
//   results.append(self[self.index ... self.index].unsafelyUnwrapped)
//  }
//  self.index = elements.startIndex
//  return results
// }
// }

public extension Peek {
 struct Storage {
  public init(
   _ elements: UnsafeMutableRawBufferPointer,
   _ index: UnsafeMutablePointer<Peek<A>.Index>
  ) {
   self.__elements = elements
   self.__index = ManagedAtomic(index)
  }

  public let __elements: UnsafeMutableRawBufferPointer
  public let __index: ManagedAtomic<UnsafeMutablePointer<Index>>
 }

 @inlinable var _index: UnsafeMutablePointer<Index> {
  storage.__index.load(ordering: .relaxed)
 }

 @inlinable var _elements: UnsafeMutableBufferPointer<A> {
  storage.__elements.bindMemory(to: A.self)
 }

 var elements: A {
  @inlinable unsafeAddress { UnsafePointer(self._elements.baseAddress.unsafelyUnwrapped) }
  @inlinable nonmutating unsafeMutableAddress { self._elements.baseAddress.unsafelyUnwrapped }
 }

 var index: Index {
  @inlinable unsafeAddress { UnsafePointer(self._index) }
  @inlinable nonmutating unsafeMutableAddress { self._index }
 }
}

extension Peek: CustomStringConvertible where A: CustomStringConvertible {
 @inlinable public var description: String { elements.description }
}

public extension Peek {
 init(
  elements: UnsafeMutableRawBufferPointer,
  index: UnsafeMutablePointer<Index>
 ) {
  self.storage = Storage(elements, index)
 }

 init(_ elements: inout A, index: inout Index) {
  self.init(
   elements: withUnsafeMutableBytes(of: &elements) { $0 },
   index: withUnsafeMutablePointer(to: &index) { $0 }
  )
 }

 init(_ elements: A) {
  var elements = elements
  var index = elements.startIndex
  self.init(&elements, index: &index)
 }

 @discardableResult
 init(
  _ elements: inout A, _ index: inout Index,
  callAsFunction: @escaping (Self) throws -> Void
 ) rethrows {
  self = Self(&elements, index: &index)
  try callAsFunction(self)
 }

 init() { self.init(.empty) }
}

// MARK: Extensions
public extension RangeReplaceableCollection {
 @inlinable var range: Range<Index> { startIndex ..< endIndex }
}

extension Slice: Equatable where Base: Equatable {
 public static func == (lhs: Slice, rhs: Slice) -> Bool {
  lhs.base == rhs.base
 }
}

public extension RangeReplaceableCollection {
 subscript(_ slice: Slice<Self>) -> SubSequence {
  self[slice.range.lowerBound ..< slice.range.upperBound]
 }
}
