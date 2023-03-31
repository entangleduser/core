protocol Destroyable: Sendable {
 associatedtype Pointee
 mutating func destroy() -> Pointee!
}

@propertyWrapper
class DestroyableBox<Value: Sendable>: Destroyable, @unchecked Sendable {
 var pointer: UnsafeLockedPointer<Value>!
 var wrappedValue: Value! {
  get { pointer.pointee }
  set { pointer.pointee = newValue }
 }

 init() {}
 init(_ value: inout Value) {
  self.pointer = .init(&value)
 }

 init(_ pointer: UnsafeLockedPointer<Value>) {
  self.pointer = pointer
 }

 @discardableResult
 func destroy() -> Value! { pointer.destroy() }
}

extension DestroyableBox where Value: Destroyable {
 @discardableResult
 func destroy() -> Value.Pointee! {
  defer { pointer = nil }
  return wrappedValue.destroy()
 }
}
