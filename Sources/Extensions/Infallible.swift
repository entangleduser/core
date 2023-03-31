public extension Optional where Wrapped: Infallible {
 @_transparent
 func unwrap(_ other: Wrapped) -> Wrapped {
  self == nil ? .defaultValue : other
 }

 @_transparent
 func unwrap(_ other: @escaping (Wrapped) -> (Wrapped)) -> Wrapped {
  self == nil ? .defaultValue : other(self!)
 }
}

public extension Infallible where Self: Equatable {
 @_transparent
 @discardableResult
 func throwing(_ error: Error? = .none) throws -> Self {
  guard self != .defaultValue else { throw error ?? UnwrapError.default(Self.self) }
  return self
 }
}

public extension ExpressibleAsEmpty where Self: Equatable {
 @_transparent
 @discardableResult
 func `throws`<A: Error>(_ error: A) throws -> A {
  guard notEmpty else { throw error }
  return error
 }
}

public extension Collection {
 @_transparent
 /// Throws a consistent error when the count is not within the given range
 func `throws`<A: Error>(_ range: Range<Int>, _ lower: A, _ upper: A) throws {
  let count = count
  guard count >= range.lowerBound else {
   guard count <= range.upperBound else { throw upper }
   throw lower
  }
 }
}
