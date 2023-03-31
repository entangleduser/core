import protocol Foundation.LocalizedError
public enum UnwrapError: LocalizedError {
 case `default`(Any.Type), reason(String)
 @_transparent
 public var failureReason: String? {
  switch self {
  case let .default(type): return "Couldn't unwrap \(type)"
  case let .reason(reason): return reason
  }
 }
}

public extension Optional {
 @_transparent
 var isNil: Bool { self == nil }
 @_transparent
 var notNil: Bool { self != nil }
 @_transparent
 func wrap(to other: Self) -> Self {
  self == nil ? other : self
 }

 @_transparent
 func wrap(_ other: @escaping (Wrapped) -> (Wrapped)) -> Self {
  self == nil ? self : other(self!)
 }

 @_transparent
 @discardableResult
 func throwing(_ error: Error? = .none) throws -> Wrapped {
  guard let self else { throw error ?? UnwrapError.default(Self.self) }
  return self
 }

 @_transparent
 @discardableResult
 func negating(_ error: Error) throws -> Bool {
  guard self == nil else { throw error }
  return true
 }
}
