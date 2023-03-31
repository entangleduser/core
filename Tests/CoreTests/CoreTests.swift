@testable import Core
import XCTest

extension UInt8: RecursiveValue {
 public var start: UInt8 { .zero }
 public var end: UInt8 { .max }
 public var previous: UInt8? { self == start ? nil : self - 1 }
 public var next: UInt8? { self == end ? nil : self + 1 }
}

final class CoreTests: XCTestCase {}
