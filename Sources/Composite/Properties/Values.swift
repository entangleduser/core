@_exported import Core
@_exported import Extensions
@_exported import OrderedCollections

public protocol KeyValues:
 Infallible, CustomReflectable, CustomStringConvertible {
 var values: [String: Any] { get set }
 /// The default values for describing purposes
 static var defaultValues: OrderedDictionary<String, Any> { get }
 subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue { get }
 subscript<A: ResolvedKey>(
  _ type: A.Type, default: A.ResolvedValue
 ) -> A.ResolvedValue { get }
 init()
}

public extension KeyValues {
 @_disfavoredOverload
 subscript<A: ResolvedKey>(_ type: A.Type) -> A.ResolvedValue {
  get { A.resolveValue(values[type.description] as? A.Value) }
  set { values[type.description] = A.storeValue(newValue) }
 }

 @_disfavoredOverload
 subscript<A: ResolvedKey>(
  _ type: A.Type, default: A.ResolvedValue
 ) -> A.ResolvedValue {
  get {
   A.resolveValue(values[type.description, default: `default`] as? A.Value)
   
  }
  set {
   values[type.description, default: A.storeValue(`default`) as Any] =
    A.storeValue(newValue) as Any
  }
 }

 subscript(any key: AnyResolvedKey) -> Any {
  get { key.resolveValue(any: values[key.description]) }
  set { values[key.description] = key.storeValue(any: newValue) }
 }

 func contains(_ type: (some ResolvedKey).Type) -> Bool {
  values.keys.contains { $0 == type.description }
 }

 func contains(key: some ResolvedKey) -> Bool {
  values.keys.contains { $0 == key.description }
 }

 func contains(name: String) -> Bool {
  values.keys.contains { $0 == name }
 }

 mutating func merge(with other: Self) {
  values.merge(other.values, uniquingKeysWith: { $1 })
 }

 func merging(with other: Self) -> Self {
  var `self` = self
  self.values.merge(other.values, uniquingKeysWith: { $1 })
  return self
 }
}

public extension KeyValues {
 static var defaultValue: Self { Self() }
 static var defaultValues: OrderedDictionary<String, Any> { .empty }

 var valuesDictionary: [String: Any] { Dictionary(uniqueKeysWithValues: valuePairs) }
 var valuePairs: [(label: String, value: Any)] {
  var array: [(String, Any)] = Self.defaultValues.map { ($0, $1) }
  array.removeAll(where: { label, _ in
   values.contains(where: { $0.key == label })
  })

  return array + values.map { ($0, $1) }
 }

 var customMirror: Mirror { Mirror(Self.self, children: valuePairs) }
 var description: String {
  """
  \(String(describing: Self.self))
  \(
   valuePairs
    .map { " \($0.label): \(type(of: $0.value)) = \("\($0.value)".readable)" }
    .joined(separator: .newline)
  )
  """
 }
}
