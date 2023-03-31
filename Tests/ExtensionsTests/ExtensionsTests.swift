import XCTest
@testable import Extensions
@testable import Core

final class ExtensionsTests: XCTestCase {
 func testAsyncQueue() async {
  var index: Parallel<[Int]>.Index = .start
  var count: Int = .zero
  var other: Parallel<[Int]>.Elements = [
   .element(0), .element(1), .element(2), .element(3),
   .elements([4, 5, 6, 7]),
   .element(8), .element(9), .element(10), .element(11),
   .elements([12, 13, 14, 15]),
   .elements((16 ..< 77).map { $0 }),
   .elements((78 ..< 500).map { $0 })
  ]

  let buffer = Parallel(&other, &index)

  for _ in buffer {
   count += 1
   print(buffer.index)
  }

  print("count is", count)
 }
}
