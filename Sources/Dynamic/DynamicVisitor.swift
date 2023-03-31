protocol DynamicVisitor: Sendable {
 func visit<A: Dynamic>(_ view: A)
}

extension Dynamic {
 func visitContent(_ visitor: some DynamicVisitor) {
  visitor.visit(content)
 }
}

// typealias DynamicVisitorF<A: DynamicVisitor> = (A) -> ()
//
// /// A type that creates a `Result` by visiting multiple `Dynamic`s.
// protocol DynamicReducer: Sendable {
// associatedtype Result: Sendable
// static func reduce<A: Dynamic>(into partialResult: inout Result, nextDynamic: A)
// static func reduce<A: Dynamic>(partialResult: Result, nextDynamic: A) -> Result
// }
//
// extension DynamicReducer {
// static func reduce<A: Dynamic>(into partialResult: inout Result, nextDynamic: A) {
//  partialResult = Self.reduce(partialResult: partialResult, nextDynamic: nextDynamic)
// }
//
// static func reduce<A: Dynamic>(partialResult: Result, nextDynamic: A) -> Result {
//  var result = partialResult
//  Self.reduce(into: &result, nextDynamic: nextDynamic)
//  return result
// }
// }
//
// /// A `DynamicVisitor` that uses a `DynamicReducer`
// /// to collapse the `Dynamic` values into a single `Result`.
// final class ReducerVisitor<R: DynamicReducer>: @unchecked Sendable, DynamicVisitor {
// var result: R.Result
//
// init(initialResult: R.Result) {
//  result = initialResult
// }
//
// func visit<A>(_ view: A) where A: Dynamic {
//   R.reduce(into: &result, nextDynamic: view)
// }
// }
//
// extension DynamicReducer {
// typealias Visitor = ReducerVisitor<Self>
// }
