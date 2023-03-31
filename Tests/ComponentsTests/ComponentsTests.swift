import XCTest
@testable import Components

struct ABC: Symbolic, Codable, CaseIterable {
 var rawValue: String = .empty

 static let a: Self = "a"
 static let b: Self = "b"
 static let c: Self = "c"

 /// - Note: Mutable in case there are cases where new symbols are needed
 static var allCases: [ABC] = [.a, .b, .c]
}

final class ComponentsTests: XCTestCase {
 func testComposite() {
  // let _ = Composite<ABC, Double>(scale: 1)
 }
}
