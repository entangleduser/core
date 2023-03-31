import Reflection
// struct AnyDynamic: Dynamic {
// let type: Sendable.Type
//
// let typeConstructorName: String
//
// var value: Sendable
// let contentClosure: @Sendable (Sendable) -> AnyDynamic
// let contentType: Sendable.Type
//
// var content: any Dynamic { contentClosure(value) }
// init<T: Dynamic>(erasing dynamic: T) {
//  if let anyDynamic = dynamic as? AnyDynamic {
//   self = anyDynamic
//  } else {
//   self.type = T.self
//   self.typeConstructorName = Reflection.typeConstructorName(self.type)
//   self.contentType = T.Contents.self
//   self.value = dynamic
//   self.contentClosure = { AnyDynamic(($0 as! T).content) }
//  }
// }
//
// init(_ dynamic: some Dynamic) {
//  self.init(erasing: dynamic)
// }
// }
//
// func mapAnyDynamic<T, D>(_ anyDynamic: AnyDynamic, transform: (D) -> T) -> T? {
// guard let dynamic = anyDynamic.value as? D else { return nil }
// return transform(dynamic)
// }
