import struct Foundation.UUID
extension UUID: ExpressibleByNilLiteral {
 @inlinable public init(nilLiteral _: ()) { self.init() }
}

public extension RawRepresentable where RawValue: ExpressibleAsEmpty {
 init(nilLiteral _: ()) { self.init(rawValue: .empty)! }
}

extension Bool: ExpressibleByNilLiteral {
 @inlinable public init(nilLiteral _: ()) { self.init(false) }
}

extension Bool: Infallible {
 @inlinable public static var defaultValue: Bool { false }
}
