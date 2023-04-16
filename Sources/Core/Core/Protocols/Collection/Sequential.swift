/// A value that automatically conforms to sequence
public protocol Sequential: Sequence where Base: Sequence {
 associatedtype Base
 override associatedtype Element = Base.Element
 override associatedtype Iterator = Base.Iterator
 var _elements: Base { get set }
 init()
}

public extension Sequential {
 init(_ elements: Base) {
  self.init()
  _elements = elements
 }

 @inlinable func makeIterator() -> Base.Iterator { _elements.makeIterator() }
}

public extension Sequential where Base: ExpressibleByArrayLiteral {
 init(_ elements: Base = .empty) {
  self.init()
  _elements = elements
 }
}
