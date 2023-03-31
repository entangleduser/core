import XCTest
@testable import Dynamic

// struct Busy: Dynamic {
// @Property(\.isEnabled) var isEnabled
// @Value var input1: String = "Lorem ipsum dolor sit amet"
// @Value var input2: String = "consectetur adipiscing elit"
// @Value var paragraph =
//  """
//  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididu\
//  nt ut labore et dolore magna aliqua.
//  """
// @Value var offset: Int = .zero {
//  didSet { self.int += 1 }
// }
//
// var str = "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
// @Value var int: Int = .zero
// }

struct Text: Dynamic {
 @Property(\.isEnabled) var isEnabled = true
 @Value var input: String
}

final class DynamicTests: XCTestCase {
 var counter: Int = .zero
 @Value var input: String = .empty
 @Value var input1: String = .empty
 @Value var input2: String = .empty
 @Value var input3: String = .empty

 @DynamicBuilder var content: some Dynamic {
  DynamicGroup {
   if counter == .zero {
    Text(input: $input)
   } else {
    Text(input: $input1)
   }
  }
  Text(input: $input2)
  Text(input: $input3)
   .modify { $0.input = "blah" }
   .modify { $0.input = "dsaf" }
   .modify { $0.input = "nbvm" }
   .modify { $0.input = "cbvc" }
   .modify { $0.input = "ghjk" }
   .modify { $0.input = "ghjk" }
   .property(\.isEnabled, false)
 }

 var storage: DynamicBuilder { .storage }
 func test() {
  let modifiedContent = content
  print(input, input2, input3)
  var values: Dynamic.Values = .defaultValue
  let result = modifiedContent.resolve(&values)
  print(result)
 }
}
