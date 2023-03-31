final class UniqueReference<Value> {
 var value: Value?
 init(_ value: Value) {
  self.value = value
 }

 @propertyWrapper
 struct Weak {
  var reference: UniqueReference?
  init(wrappedValue: Value? = nil) {
   if let wrappedValue {
    self.reference = UniqueReference(wrappedValue)
   }
  }

  var wrappedValue: Value? {
   get { reference?.value }
   set {
    if isKnownUniquelyReferenced(&reference) {
     reference?.value = newValue
    } else {
     reference = UniqueReference(newValue.unsafelyUnwrapped)
    }
   }
  }
 }
}
