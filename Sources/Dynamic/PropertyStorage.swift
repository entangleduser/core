@_exported import Reflection
@_exported import Extensions
@_exported import Transactions

func withHash(for value: some Any) -> AnyHashable {
 if let property = Mirror(reflecting: value).children.first(where: { $0.label == "id" }),
    let value = property.value as? AnyHashable {
  return value
 } else {
  return AnyHashable("\(value)")
 }
}

struct PropertyCache: ExpressibleAsEmpty {
 static let empty = PropertyCache()
 var isEmpty: Bool { cache.isEmpty }
 var cache: [Int: PropertyInfo] = .empty
 subscript(_ offset: Int) -> PropertyInfo? {
  get { cache[offset] }
  set {
   guard let newValue else { return }
   cache[offset] = newValue
  }
 }
}

class PropertyStorage {
 // var buffer: [ObjectIdentifier: [any Dynamic]] = .empty
 var objects: [PropertyIdentifier: AnyObject] = .empty
 var properties: [PropertyIdentifier: PropertyCache] = .empty
 var valueOffset: [ObjectIdentifier: Int] = .empty

 func object<A: Dynamic>(at offset: Int) -> A.Projection {
  objects[PropertyIdentifier(A.self, offset)] as! A.Projection
 }

 func add<A: Dynamic>(_ value: A, values: A.Values? = nil) {
  if valueOffset[value.identifier] == nil {
   valueOffset[value.identifier] = .zero
   let id = PropertyIdentifier(type(of: value), .zero)
   if objects[id] == nil {
    objects[id] = Object(value, self, values: values)
   }
  } else {
   let offset = valueOffset[value.identifier]!
   let id = PropertyIdentifier(type(of: value), offset + 1)
   objects[id] = Object(value, self, values: values)
   valueOffset[value.identifier] = offset + 1
  }
 }
}

protocol StaticPropertyStorage: PropertyStorage {
 func update(_ value: Any, at offset: Int)
 func update(_ property: some StaticProperty)
}

@dynamicMemberLookup
protocol DynamicPropertyStorage: StaticPropertyStorage {
 associatedtype A: Dynamic
 typealias Values = A.Values
 var storage: PropertyStorage! { get set }
 var propertyCache: PropertyCache { get set }
 var value: A { get set }
 var values: A.Values { get set }
}

extension DynamicPropertyStorage {
 subscript<Value>(dynamicMember keyPath: WritableKeyPath<A, Value>) -> Value {
  get { value[keyPath: keyPath] }
  set { value[keyPath: keyPath] = newValue }
 }
}

@dynamicMemberLookup
class Object<A: Dynamic>: PropertyStorage, DynamicPropertyStorage {
 convenience init(
  _ value: A,
  _ storage: PropertyStorage,
  values: Values? = nil
 ) {
  self.init()
  self.value = value
  if let values {
   self.values = values
  }
  self.storage = storage
  self.cacheProperties()
 }

 convenience init(
  _ value: inout A,
  _ storage: PropertyStorage,
  values: Values? = nil
 ) {
  self.init(value, storage, values: values)
  self.reference = withUnsafeLockedPointer(&value) { $0 }
 }

 unowned var storage: PropertyStorage!
 unowned var root: PropertyStorage?
 var identifier: ObjectIdentifier { self.value.identifier }
 @UnsafeAtomicLazy var value: A { didSet { self.update() } }
 lazy var reference: UnsafeLockedPointer<A>? = nil
 var values: Values = .defaultValue
 var read = false

 subscript<Value>(dynamicMember keyPath: WritableKeyPath<Values, Value>) -> Value {
  get { self.values[keyPath: keyPath] }
  set { self.values[keyPath: keyPath] = newValue }
 }

 func cacheProperties() {
  for property in self.value.metadata.properties() {
   self.propertyCache[property.offset] = property
   if var `static` = property.get(from: value as Any) as? StaticProperty {
    `static`._offset = .init(property.offset)
    `static`._reference = .init(self)
    property.set(value: `static`, on: &self.value)
   } else if var dynamic = property.get(from: value as Any) as? DynamicProperty {
    dynamic.update()
    property.set(value: dynamic, on: &self.value)
   }
  }
  self.read = true
 }

 var propertyCache: PropertyCache {
  get { self.storage.properties[self.value.metadata.id, default: .defaultValue] }
  set {
   self.storage.properties[self.value.metadata.id, default: .defaultValue] = newValue
  }
 }

 func update() { self.reference?.pointee = self.value }

 func update(_ newValue: Any, at offset: Int) {
  if let property = propertyCache[offset] {
   property.set(value: newValue, on: &self.value)
  }
 }

 func update(_ property: some StaticProperty) {
  if let offset = property.offset { self.update(property, at: offset) }
 }

 deinit { print("\(value) was deinitialized") }
}

@resultBuilder class DynamicBuilder: PropertyStorage {
 static let storage = DynamicBuilder()
 static func buildBlock() -> EmptyDynamic { EmptyDynamic() }
// static func buildFinalResult(_ component: TupleDynamic<) -> DynamicContent {
//
// }
// static func buildBlock<A: Dynamic>(_ dynamic: A) -> some Dynamic {
//  if dynamic is RootDynamic {
//  }
//  if dynamic is GroupDynamic {
//  }
//  return dynamic
 ////  if let (value, values) = storage.unwrap(value: dynamic) {
 ////   self.storage.add(value, values: values)
 ////   return AnyDynamic(value)
 ////  } else {
 ////   return AnyDynamic(dynamic)
 ////  }
// }

 static func buildBlock(_ components: (any Dynamic)...) -> some Dynamic {
  var resolvedComponents: [any Dynamic] = .empty
  for value in components {
   var values: DynamicValues = .defaultValue
   let resolvedValue = value.resolve(&values)
   storage.add(resolvedValue, values: values.values.notEmpty ? values : nil)
   resolvedComponents.append(resolvedValue)
  }
  return DynamicElements(resolvedComponents)
//  self.storage.valueOffset = .defaultValue
 }

 static func buildOptional<A: Dynamic>(_ dynamic: A?) -> A? { dynamic }
 static func buildIf<A: Dynamic>(_ dynamic: A?) -> A? { dynamic }
// static func buildEither<A: Dynamic>(
//  first: A
// ) -> some Dynamic {
 ////  ConditionalDynamic(storage: .trueContent(first))
//  buildBlock(first)
// }
//
// static func buildEither<B: Dynamic>(
//  second: B
// ) -> some Dynamic {
//  buildBlock(second)
// }

 static func buildEither<A: Dynamic, B: Dynamic>(
  first: A
 ) -> ConditionalDynamic<A, B> {
  ConditionalDynamic(storage: .trueContent(first))
 }

 static func buildEither<A: Dynamic, B: Dynamic>(
  second: B
 ) -> ConditionalDynamic<A, B> {
  ConditionalDynamic(storage: .falseContent(second))
 }
}

struct ConditionalDynamic<A, B>: Dynamic
where A: Dynamic, B: Dynamic {
 enum Storage {
  case trueContent(A)
  case falseContent(B)
 }

 let storage: Storage
 var content: some Dynamic {
  switch storage {
  case let .trueContent(content): content
  case let .falseContent(content): content
  }
 }
}

// MARK: - Other
// extension DynamicBuilder {
// static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleDynamic<(C0, C1)>
// where C0: Dynamic, C1: Dynamic
// {
// TupleDynamic(c0, c1)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2
// ) -> TupleDynamic<(C0, C1, C2)> where C0: Dynamic, C1: Dynamic, C2: Dynamic {
//  TupleDynamic(c0, c1, c2)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3
// ) -> TupleDynamic<(C0, C1, C2, C3)> where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic {
//  TupleDynamic(c0, c1, c2, c3)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3, C4>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3,
//  _ c4: C4
// ) -> TupleDynamic<(C0, C1, C2, C3, C4)> where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic, C4: Dynamic {
//  TupleDynamic(c0, c1, c2, c3, c4)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3, C4, C5>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3,
//  _ c4: C4,
//  _ c5: C5
// ) -> TupleDynamic<(C0, C1, C2, C3, C4, C5)>
// where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic, C4: Dynamic, C5: Dynamic
// {
// TupleDynamic(c0, c1, c2, c3, c4, c5)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3, C4, C5, C6>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3,
//  _ c4: C4,
//  _ c5: C5,
//  _ c6: C6
// ) -> TupleDynamic<(C0, C1, C2, C3, C4, C5, C6)>
// where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic, C4: Dynamic, C5: Dynamic, C6: Dynamic
// {
// TupleDynamic(c0, c1, c2, c3, c4, c5, c6)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3,
//  _ c4: C4,
//  _ c5: C5,
//  _ c6: C6,
//  _ c7: C7
// ) -> TupleDynamic<(C0, C1, C2, C3, C4, C5, C6, C7)>
// where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic, C4: Dynamic, C5: Dynamic, C6: Dynamic, C7: Dynamic
// {
// TupleDynamic(c0, c1, c2, c3, c4, c5, c6, c7)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3,
//  _ c4: C4,
//  _ c5: C5,
//  _ c6: C6,
//  _ c7: C7,
//  _ c8: C8
// ) -> TupleDynamic<(C0, C1, C2, C3, C4, C5, C6, C7, C8)>
// where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic, C4: Dynamic, C5: Dynamic, C6: Dynamic, C7: Dynamic, C8: Dynamic
// {
// TupleDynamic(c0, c1, c2, c3, c4, c5, c6, c7, c8)
// }
// }
//
// extension DynamicBuilder {
// static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9>(
//  _ c0: C0,
//  _ c1: C1,
//  _ c2: C2,
//  _ c3: C3,
//  _ c4: C4,
//  _ c5: C5,
//  _ c6: C6,
//  _ c7: C7,
//  _ c8: C8,
//  _ c9: C9
// ) -> TupleDynamic<(C0, C1, C2, C3, C4, C5, C6, C7, C8, C9)>
// where C0: Dynamic, C1: Dynamic, C2: Dynamic, C3: Dynamic, C4: Dynamic, C5: Dynamic, C6: Dynamic, C7: Dynamic, C8: Dynamic,
//       C9: Dynamic
// {
// TupleDynamic(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
// }
// }
//
