extension Date: Infallible {
 @_disfavoredOverload
 public static let defaultValue: Self = .init()
}

extension Date: ExpressibleByNilLiteral {
 public init(nilLiteral: ()) { self.init() }
}

public extension Date {
 /// Initialize a date within a specific range based on 'second' intervals
 static func random(_ range: Range<Int> = -2_332_800 ..< -60) -> Self {
  Date(timeIntervalSinceNow: Double(range.randomElement()!))
 }
}

extension Date: Randomizable {
 public mutating func randomize() {
  self = .random()
 }
}
