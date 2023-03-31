public struct PropertyInfo {
 public let name: String
 public let type: Any.Type
 public let isVar: Bool
 public let offset: Int
 public let ownerType: Any.Type

 public func set(value: Any, on object: inout some Any) {
  withValuePointer(of: &object) { pointer in
   set(value: value, pointer: pointer)
  }
 }

 public func set(value: Any, on object: inout Any) {
  withValuePointer(of: &object) { pointer in
   set(value: value, pointer: pointer)
  }
 }

 private func set(value: Any, pointer: UnsafeMutableRawPointer) {
  let valuePointer = pointer.advanced(by: offset)
  let sets = setters(type: type)
  sets.set(value: value, pointer: valuePointer)
 }

 public func get(from object: Any) -> Any {
  var object = object
  return withValuePointer(of: &object) { pointer in
   let valuePointer = pointer.advanced(by: offset)
   let gets = getters(type: type)
   return gets.get(from: valuePointer)
  }
 }
}
