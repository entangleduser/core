@_exported import Atomics
@propertyWrapper struct UnsafeAtomicReference<Value: AnyObject> {
 init() {}
 unowned var reference: Value? {
  willSet {
   guard reference == nil, let newValue else { return }
   _ = projectedValue.storeIfNilThenLoad(newValue)
  }
 }

 var projectedValue = ManagedAtomicLazyReference<Value>()
 @inlinable var wrappedValue: Value {
  get { projectedValue.load().unsafelyUnwrapped }
  set { reference = newValue }
 }
}

@propertyWrapper public struct DefaultAtomic<Value: AtomicValue & Infallible> {
 public init() {}
 public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }

 public let projectedValue = ManagedAtomic<Value>(.defaultValue)
 @inlinable public var wrappedValue: Value {
  get { projectedValue.load(ordering: .relaxed) }
  nonmutating set {
   projectedValue.store(newValue, ordering: .relaxed)
  }
 }
}
