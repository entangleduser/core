@dynamicMemberLookup
/// Container for all cached inherited properties of a structure
public struct InheritedPropertyStorage<Values: KeyValues>: InheritedPropertyCache {
 public init(
  _parent: UnsafeMutablePointer<InheritedPropertyStorage<Values>>? = nil,
  cache: [String: () -> Any] = .empty,
  values: Values? = nil
 ) {
  self._parent = _parent
  self.cache = cache
  self.values = values
 }

 public var _parent: UnsafeMutablePointer<Self>?
 public var cache: [String: () -> Any] = .empty
 /// - Note: Values shouldn't copy, unless set by the structure
 /// Accessing these values should be through the `defaultValue` by default
 /// If modification is needed a new one will be created to alter the dictionary
 public var values: Values?

 public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Values, Value>) -> Value {
  get { values![keyPath: keyPath] }
  set {
   values?[keyPath: keyPath] = newValue
  }
 }
}
