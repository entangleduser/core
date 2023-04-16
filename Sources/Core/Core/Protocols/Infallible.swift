/// A type that has a default value.
public protocol Infallible {
 static var defaultValue: Self { get }
}

extension Optional: Infallible where Wrapped: Infallible {
 @inlinable public var unwrapped: Wrapped { self ?? .defaultValue }
 @inlinable public static var defaultValue: Wrapped? { Wrapped.defaultValue }
}

// MARK: Conformance Helpers
public extension ExpressibleAsEmpty {
 @inlinable static var defaultValue: Self { empty }
}

public extension ExpressibleAsZero {
 @inlinable static var defaultValue: Self { zero }
}

import struct Foundation.UUID
extension UUID: Infallible {
 @inlinable public static var defaultValue: Self { Self() }
}
