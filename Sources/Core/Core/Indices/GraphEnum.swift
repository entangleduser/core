// enum GraphEnum<Base: MutableCollection>: RecursiveIndex
// where Base: ExpressibleByArrayLiteral, Base.Index: Equatable & Comparable {
// typealias Recursive = [Self]
// case linear(Int, Base.Index), recursive(Recursive)
// var index: Int {
//  get {
//   switch self {
//    case let .linear(index, _): return index
//    default: return .zero
//   }
//  }
//  set { self = .linear(newValue, offset) }
// }
//
// var offset: Base.Index {
//  get {
//   switch self {
//    case let .linear(_ , offset): return offset
//    default: return Base.empty.startIndex
//   }
//  }
//  set { self = .linear(index, newValue) }
// }
//
// init(index: Int = .zero, offset: Base.Index) {
//  self = .linear(index, offset)
// }
// }
//
