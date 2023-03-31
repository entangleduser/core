// @dynamicMemberLookup
/// Container for all cached inherited properties of a structure
struct InheritedPropertyStorage<Values: KeyValues>: InheritedPropertyCache {
 var cache: [String: () -> Any] = .empty
 /// Values shouldn't copy, unless set by the structure
 /// Accessing these values should be through the `defaultValue` by default
 /// If modification is needed a new one will be created to alter the dictionary
 var values: Values?

 var _parent: UnsafeMutablePointer<Self>?

// subscript<Value>(dynamicMember keyPath: WritableKeyPath<Values, Value?>) -> Value? {
//  get { values?[keyPath: keyPath] }
//  set {
//   guard let newValue else { return }
//   values?[keyPath: keyPath] = newValue
//  }
// }
}
