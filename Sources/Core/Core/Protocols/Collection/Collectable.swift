public protocol Collectable: Sequential & Collection, ExpressibleAsEmpty {
 override associatedtype Base: Collection
 override associatedtype Element = Base.Element
 override associatedtype Iterator = Base.Iterator
 override associatedtype Index = Base.Index
 override associatedtype Indices = Base.Indices
 override associatedtype SubSequence = Base.SubSequence
}

public extension Collectable {
 @inlinable var startIndex: Base.Index { _elements.startIndex }
 @inlinable var endIndex: Base.Index { _elements.endIndex }
 @inlinable var indices: Base.Indices { _elements.indices }
 @inlinable func index(after i: Base.Index) -> Base.Index {
  _elements.index(after: i)
 }

 @inlinable
 subscript(position: Base.Index) -> Base.Element { _elements[position] }
 @inlinable
 subscript(bounds: Range<Base.Index>) -> Base.SubSequence { _elements[bounds] }
 @inlinable func index(_ i: Base.Index, offsetBy distance: Int) -> Base.Index {
  _elements.index(i, offsetBy: distance)
 }

 @inlinable func index(
  _ i: Base.Index, offsetBy distance: Int, limitedBy limit: Base.Index
 ) -> Base.Index? {
  _elements.index(i, offsetBy: distance, limitedBy: limit)
 }

 @inlinable func distance(from start: Base.Index, to end: Base.Index) -> Int {
  _elements.distance(from: start, to: end)
 }

 @inlinable func formIndex(after i: inout Base.Index) {
  _elements.formIndex(after: &i)
 }

 @inlinable var count: Int { _elements.count }

 @inlinable
 var isEmpty: Bool { _elements.isEmpty }
}
