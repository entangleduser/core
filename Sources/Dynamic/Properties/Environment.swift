import class Atomics.ManagedAtomic
import class Swift.WritableKeyPath
extension WritableKeyPath: @unchecked Sendable {}

protocol EnvironmentProperty: DefaultProperty, StaticProperty where Wrapped: Sendable {
 associatedtype Wrapper: Dynamic
 associatedtype ResolvedValue
 typealias Projection = Wrapper.Projection
 typealias Values = Projection.Values
 var keyPath: WritableKeyPath<Values, ResolvedValue> { get }
}

extension EnvironmentProperty {
 var projection: Projection? {
  get { reference as? Projection }
  set { reference = newValue }
 }

 var values: Values? {
  get { projection?.values }
  set {
   guard let newValue else { return }
   projection?.values = newValue
  }
 }
}

@dynamicMemberLookup
@propertyWrapper
struct DefaultEnvironmentProperty
<Wrapped: Sendable, Wrapper: Dynamic>: EnvironmentProperty, @unchecked Sendable {
 typealias ResolvedValue = Wrapped
 var _reference: UniqueReference<StaticPropertyStorage>.Weak? {
  didSet {
   guard projection != nil else { fatalError("Missing projection for \(Wrapper.self)") }
   if let defaultValue { values![keyPath: keyPath] = defaultValue }
  }
 }

 var _offset: ManagedAtomic<Int>?
 let keyPath: WritableKeyPath<Values, ResolvedValue>

 @Value var defaultValue: Wrapped? = nil
 var wrappedValue: Wrapped {
  get {
   defaultValue ??
    values?[keyPath: keyPath] ??
    Values.defaultValue[keyPath: keyPath]
  }
  nonmutating set {
   guard let projection else {
    self.defaultValue = newValue
    return
   }
   projection.values[keyPath: keyPath] = newValue
   self.defaultValue = nil
   update()
  }
 }

 public var projectedValue: Value<Wrapped> {
  Value(get: { wrappedValue }, set: { wrappedValue = $0 })
 }

 subscript<Value>(dynamicMember keyPath: WritableKeyPath<Wrapped, Value>) -> Value {
  get { wrappedValue[keyPath: keyPath] }
  nonmutating set { wrappedValue[keyPath: keyPath] = newValue }
 }

 init(wrappedValue: Wrapped? = nil, _ keyPath: WritableKeyPath<Values, ResolvedValue>) {
  self.keyPath = keyPath
  if let wrappedValue { defaultValue = wrappedValue }
 }
}

extension DefaultEnvironmentProperty: StaticProperty {}
extension DefaultEnvironmentProperty: CustomStringConvertible

 where Wrapped: CustomStringConvertible {
 var description: String { wrappedValue.description }
}

struct OptionalEnvironmentProperty
<Wrapped: Sendable, Wrapper: Dynamic>: EnvironmentProperty, @unchecked Sendable {
 typealias ResolvedValue = Wrapped?
 var _reference: UniqueReference<StaticPropertyStorage>.Weak? {
  didSet {
   guard projection != nil else { fatalError("Missing projection for \(Wrapper.self)") }
   if let defaultValue { values![keyPath: keyPath] = defaultValue }
  }
 }

 var _offset: ManagedAtomic<Int>?
 let keyPath: WritableKeyPath<Values, ResolvedValue>

 @Value var defaultValue: Wrapped? = nil
 var wrappedValue: Wrapped? {
  get {
   defaultValue ??
    values?[keyPath: keyPath] ??
    Values.defaultValue[keyPath: keyPath]
  }
  nonmutating set {
   guard let projection else {
    self.defaultValue = newValue
    return
   }
   projection.values[keyPath: keyPath] = newValue
   self.defaultValue = nil
   update()
  }
 }

 public var projectedValue: Value<Wrapped?> {
  Value(get: { wrappedValue }, set: { wrappedValue = $0 })
 }

 subscript<Value>(dynamicMember keyPath: WritableKeyPath<Wrapped, Value>) -> Value? {
  get { wrappedValue?[keyPath: keyPath] }
  nonmutating set {
   guard let newValue else { return }
   wrappedValue?[keyPath: keyPath] = newValue
  }
 }

 init(wrappedValue: Wrapped? = nil, _ keyPath: WritableKeyPath<Values, ResolvedValue>) {
  self.keyPath = keyPath
  if let wrappedValue { defaultValue = wrappedValue }
 }
}

extension Dynamic {
 typealias Property<Value> = DefaultEnvironmentProperty<Value, Self>
 typealias OptionalProperty<Value> = OptionalEnvironmentProperty<Value, Self>
}
