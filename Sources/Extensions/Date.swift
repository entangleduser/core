import struct Foundation.Date
extension Date: Infallible {
 @_disfavoredOverload
 @inlinable public static var defaultValue: Self { .init() }
}

extension Date: ExpressibleByNilLiteral {
 @inlinable public init(nilLiteral: ()) { self.init() }
}

public extension Date {
 /// Initialize a date within a specific range based on 'second' intervals
 @inlinable static func random(
  _ range: Range<Int> = -2_332_800 ..< -60
 ) -> Self {
  Date(timeIntervalSinceNow: Double(range.randomElement()!))
 }
}

extension Date: Randomizable {
 @inlinable public mutating func randomize() {
  self = .random()
 }
}
