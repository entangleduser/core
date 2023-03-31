// postfix operator ~
/// A type that has a default value.
public protocol Infallible {
 static var defaultValue: Self { get }
}

// public extension Infallible {
//	@inlinable
//	static postfix func ~(_ type: Self.Type) -> Self { defaultValue }
// }

extension Optional: Infallible where Wrapped: Infallible {
 @inlinable
 public var unwrapped: Wrapped { self ?? .defaultValue }
 @inlinable
 public static var defaultValue: Wrapped? { Wrapped.defaultValue }
 //	@inlinable
 //	static postfix func ~(_ value: Self) -> Wrapped { value.unwrapped }
}

// MARK: Conformance Helpers

// FIXME: Conform to protocol `Infallible`
public extension ExpressibleByNilLiteral {
// @inlinable
// static var defaultValue: Self { nil }
}

public extension ExpressibleAsEmpty {
 @inlinable
 static var defaultValue: Self { empty }
}

public extension ExpressibleAsZero {
 @inlinable
 static var defaultValue: Self { zero }
}
