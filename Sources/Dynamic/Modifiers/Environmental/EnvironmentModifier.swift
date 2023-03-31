@dynamicMemberLookup
protocol EnvironmentModifier: DynamicModifier, Dynamic where ModifiedContent == Content {
 var content: Content { get set }
 func modify(_ values: inout DynamicValues)
}

extension EnvironmentModifier {
 func content(_ content: Content) -> ModifiedContent { self.content }
 subscript<Value>(dynamicMember keyPath: WritableKeyPath<Content, Value>) -> Value {
  get { content[keyPath: keyPath] }
  set { content[keyPath: keyPath] = newValue }
 }
}

struct EnvironmentWritingModifier
<A: Dynamic, B: Sendable>: EnvironmentModifier {
 typealias Content = A
 init(content: Content, keyPath: WritableKeyPath<DynamicValues, B>, value: B) {
  self.content = content
  self.keyPath = keyPath
  self.value = value
  for property in self.content.metadata.properties() {
   if let wrapper =
    property.get(from: content) as? DefaultEnvironmentProperty<B, A> {
    if wrapper.keyPath == keyPath {
     wrapper.defaultValue = self.value
    }
    property.set(value: wrapper, on: &self.content)
   } else if let wrapper =
    property.get(from: content) as? DefaultEnvironmentProperty<B, A> {
    if wrapper.keyPath == keyPath {
     wrapper.defaultValue = self.value
    }
    property.set(value: wrapper, on: &self.content)
   }
  }
 }

 var content: A
 let keyPath: WritableKeyPath<DynamicValues, B>
 let value: B
 func modify(_ values: inout DynamicValues) {
  values[keyPath: keyPath] = value
 }
}

extension Dynamic {
 func property<Value>(
  _ keyPath: WritableKeyPath<Values, Value>, _ value: Value
 ) -> EnvironmentWritingModifier<Self, Value> {
  EnvironmentWritingModifier<Self, Value>(content: self, keyPath: keyPath, value: value)
 }
}
