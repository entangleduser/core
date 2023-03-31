protocol ResolvedValues: Sendable {
 var values: [String: Sendable] { get set }
 static var defaultValues: [String: Sendable] { get }
 init()
}

extension ResolvedValues {
 static var defaultValue: Self { Self() }

 var allValuesArray: [(label: String, value: Sendable)] {
  var array: [(String, Any)] = Self.defaultValues.map { ($0, $1) }
  array.removeAll(where: { label, _ in values.contains(where: { $0.key == label }) })
  return array + values.map { ($0, $1) }
 }

 var allValues: [String: Sendable] {
  Dictionary(uniqueKeysWithValues: allValuesArray)
 }

 var customMirror: Mirror {
  Mirror(Self.self, children: allValuesArray)
 }

 var description: String {
  """
  \(String(describing: Self.self))
  \(
   allValuesArray
    .map { "\($0.label): \(type(of: $0.value)) = \($0.value)" }
    .joined(separator: .newline)
  )
  """
 }
}
