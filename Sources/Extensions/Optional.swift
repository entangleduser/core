import protocol Foundation.LocalizedError
public enum UnwrapError: LocalizedError {
 case `default`(Any.Type), reason(String)
 @inlinable public var failureReason: String? {
  switch self {
  case let .default(type): return "Couldn't unwrap \(type)"
  case let .reason(reason): return reason
  }
 }
}

public extension Optional {
 @inlinable var isNil: Bool { self == nil }
 @inlinable var notNil: Bool { self != nil }
 @inlinable func wrap(to other: Self) -> Self {
  self == nil ? other : self
 }

 @inlinable func wrap(_ other: @escaping (Wrapped) -> (Wrapped)) -> Self {
  self == nil ? self : other(self!)
 }

 @inlinable
 @discardableResult func throwing(_ error: Error? = .none) throws -> Wrapped {
  guard let self else { throw error ?? UnwrapError.default(Self.self) }
  return self
 }

 @inlinable
 @discardableResult func negating(_ error: Error) throws -> Bool {
  guard self == nil else { throw error }
  return true
 }
}
