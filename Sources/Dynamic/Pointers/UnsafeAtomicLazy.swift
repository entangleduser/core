@propertyWrapper struct UnsafeAtomicLazy<Value> {
 lazy var value: Value? = nil
 let lock = NSLock()
 var wrappedValue: Value {
  mutating get { value.unsafelyUnwrapped }
  mutating set {
   lock.lock()
   value = newValue
   lock.unlock()
  }
 }
}
