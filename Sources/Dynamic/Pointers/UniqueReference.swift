
final class UniqueReference<Value: Sendable>: @unchecked Sendable {
 var value: Value?
 init(_ value: Value) {
  self.value = value
 }

 @propertyWrapper
 struct Weak: @unchecked Sendable {
  var reference: UniqueReference?
  init(_ value: Value? = nil) {
   if let value {
    self.reference = UniqueReference(value)
   }
  }

  var wrappedValue: Value? {
   get { reference?.value }
   set {
    if isKnownUniquelyReferenced(&reference) {
     reference?.value = newValue
     // UniqueReference(newValue.unsafelyUnwrapped)
    } else {
     reference = UniqueReference(newValue.unsafelyUnwrapped)
    }
   }
  }
 }
}
