protocol Destroyable {
 associatedtype Pointee
 func destroy() -> Pointee?
}

@propertyWrapper
struct DestroyableBox<Value>: Destroyable {
 init() {}
 init(_ pointer: UnsafeMutablePointer<Value?>) { self.pointer = pointer }
 init(_ value: inout Value?, offset: Int) {
  self.pointer = withUnsafeMutablePointer(to: &value) { $0 }
 }

 var pointer: UnsafeMutablePointer<Value?> = nil
 var wrappedValue: Value? {
  get { pointer == nil ? nil : pointer.pointee }
  nonmutating set {
   guard nil ~= newValue else {
    self.pointer.deallocate()
    return
   }
   self.pointer.pointee = newValue
  }
 }

 @discardableResult
 func destroy() -> Value? {
  defer { self.pointer.deallocate() }
  return wrappedValue
 }
}

extension DestroyableBox where Value: Destroyable {
 @discardableResult
 func destroy() -> Value.Pointee? { destroy()?.destroy() }
}
