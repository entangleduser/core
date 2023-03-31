struct PropertyIdentifier: Hashable {
 init(value: some Any, offset: Int) {
  self.subject = type(of: value)
  self.offset = offset
 }

 init(subject: Any.Type, offset: Int) {
  self.subject = subject
  self.offset = offset
 }

 let subject: Any.Type
 let offset: Int

 func hash(into hasher: inout Hasher) {
  hasher.combine(String(describing: subject))
  hasher.combine(offset)
 }

 static func == (lhs: Self, rhs: Self) -> Bool { lhs.hashValue == rhs.hashValue }
}

struct TypedPropertyIdentifier<Value>: PropertyKey {
 init(value: Value, offset: Int) {
  self.offset = offset
 }

 init(subject: Value.Type, offset: Int) {
  self.offset = offset
 }

 var subject: String { String(describing: Value.self) }
 let offset: Int

 var description: String { subject + offset.description }

 func hash(into hasher: inout Hasher) {
  hasher.combine(subject)
  hasher.combine(offset)
 }
}

protocol InheritenceProtocol {
 var _parent: UnsafeMutablePointer<Self>? { get set }
}

extension InheritenceProtocol {
 var hasParent: Bool { self._parent != nil }
 /// Assign parent from the mirror
 mutating func assign(to parent: inout Self) {
  _parent = withUnsafeMutablePointer(to: &parent) { $0 }
 }

 @inlinable var parent: Self {
  unsafeAddress { UnsafePointer(_parent.unsafelyUnwrapped) }
  nonmutating unsafeMutableAddress { _parent.unsafelyUnwrapped }
 }
}

/// Container for all cached properties of a structure, as well as dynamic property info
/// for publishers to access
/// An ``Indexer`` should allow the structure to update dynamic properties by
/// introspecting this container
protocol PropertyCache {
 var cache: [String: () -> Any] { get set }
 // init()
}

extension PropertyCache {
 subscript<Key: PropertyKey & CustomStringConvertible>(_ key: Key) -> Key.Value? {
  get { cache[key.description]?() as? Key.Value }
  set { cache[key.description] = { newValue as Any } }
 }

 subscript<Key: PropertyKey & CustomStringConvertible>(
  _ key: Key, default: Key.Value
 ) -> Key.Value {
  get { cache[key.description, default: { `default` }]() as! Key.Value }
  set { cache[key.description, default: { `default` }] = { newValue }}
 }
}

extension String {
 init(mangled name: String) { self.init(name.prefix { $0 != "<" }) }
 static func mangledName(for name: String) -> Self { String(mangled: name) }

 static func withName(for type: Any.Type) -> Self {
  Self(mangled: String(describing: type))
 }
}

protocol IndexedPropertyCache: PropertyCache {
 /// A reflection of the property types when setting the cache or binding
 /// Used to update properties by index, which is useful for some frameworks
 var types: Set<String> { get set }
 static var types: Set<String> { get }
}

extension IndexedPropertyCache {
 @inlinable mutating func add(type: Any.Type) {
  let name: String = .withName(for: type)
  if Self.types.contains(name) { types.insert(name) }
 }

 @inlinable mutating func add(name: String) {
  if Self.types.contains(name) { types.insert(name) }
 }

 @inlinable func contains(type: Any.Type) -> Bool { types.contains(.withName(for: type)) }
 @inlinable func contains(name: String) -> Bool { types.contains(name) }
}

/// A storage protocol for passing inherited properties
/// If a cache must store attributes the cache will be used
/// Otherwise key paths are the main way to access a property
/// To manage the difference between using the cache or value storage
/// the `cache` must be checked from the property wrapper
/// This is dependent on whether or not an inherited cache needs default attributes
/// Sometimes, we want to set the default value but if there are conditions with the
/// publisher or parent cache that supercede default access it has to be unwrapped before
/// loading the default value. Determining whether or not to store the default value
/// is dependent on a publisher being in the loop or inheritence, which can be checked
/// before caching defaults or creating a new property. The idea for key path attributes is to
/// have it take from a parent determined by the builder or by creating it's own environment
/// storage.
protocol InheritedPropertyCache: PropertyCache, InheritenceProtocol {
 associatedtype Values: KeyValues
 var values: Values? { get set }
}

extension InheritedPropertyCache {
 mutating func converge() {
  values!.merge(with: parent.values.unsafelyUnwrapped)
 }

// subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
//  get {
//   // if the current value for `A` is nil return the parent instead of the default
//   // that will return if using the subscript
//   if let values, values.contains(type) {
//    return values[type]
//   } else {
//    return parent.values?[type] as? A.ResolvedValue ?? A.resolvedValue
//   }
//  }
//  set {
//   /// - note: this only stores the new value, it doesn't check to see if the parent
//   /// already has it
//   if values == nil { self.values = .defaultValue }
//   values?[type] = newValue
//  }
// }
//
// subscript<A: ResolvedKey>(_ type: A.Type, default: A.ResolvedValue) -> A.ResolvedValue {
//  get {
//   if let values, values.contains(type) {
//    return values[type, `default`]
//   } else {
//    return parent.values?[type, `default`] as? A.ResolvedValue ?? A.resolvedValue
//   }
//  }
//  set {
//   if values == nil { self.values = .defaultValue }
//   values?[type, `default`] = newValue
//  }
// }

 subscript(key: AnyResolvedKey) -> Any {
  get {
   // if the current value for `A` is nil return the parent instead of the default
   // that will return if using the subscript
   if let values, values.contains(key: key) {
    return values[any: key]
   } else if hasParent {
    return parent.values?[any: key] as Any
   }
   return values![any: key]
  }
  set {
   /// - note: this only stores the new value, it doesn't check to see if the parent
   /// already has it
   if values == nil { values = .defaultValue }
//   guard let newValue else {
//    values?[any: key] = nil
//    return
//   }
   values?[any: key] = newValue
  }
 }

 subscript(name: String) -> Any? {
  get {
   // if the current value for `A` is nil return the parent instead of the default
   // that will return if using the subscript
   if let values, values.contains(name: name) {
    return values.values[name]
   } else if hasParent {
    return parent.values?.values[name]
   }
   return nil
  }
  set {
   /// - note: this only stores the new value, it doesn't check to see if the parent
   /// already has it
   if values == nil { values = .defaultValue }
   guard let newValue else {
    values?.values[name] = nil
    return
   }
   values?.values[name] = newValue
  }
 }

// subscript<A: ResolvedKey>(key: A, default: A.Value) -> A.ResolvedValue {
//  get {
//   if let values, values.contains(key: key) {
//    return values[key, default: `default`]
//   } else if hasParent {
//    return parent.values?.values[name, default: `default`] as Any
//   }
//   return `default`
//  }
//  set {
//   if values == nil { self.values = .defaultValue }
//   values?.values[name, default: `default`] = newValue
//  }
// }
}
