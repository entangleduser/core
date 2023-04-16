import Foundation

struct UnsafeLockedPointer<Pointee: Sendable>: Destroyable {
 var base: UnsafeRawLockedPointer
 var pointer: UnsafeMutablePointer<Pointee?> {
  base.wrappedValue.assumingMemoryBound(to: Pointee?.self)
 }

 @inlinable var pointee: Pointee! {
  unsafeAddress { UnsafePointer(pointer) }
  nonmutating unsafeMutableAddress { pointer }
 }

 @discardableResult
 func destroy() -> Pointee! {
  defer { pointee = .none }
  return pointee
 }

 init(_ value: inout Pointee) {
  self.base = .init(&value)
 }
}

struct UnsafeRawLockedPointer: Hashable {
 var _value: UnsafeMutableRawPointer
 var wrappedValue: UnsafeMutableRawPointer {
  get { _value }
  set {
   rawValue.lockThread()
   _value = newValue
   rawValue.unlockThread()
  }
 }

 var rawValue: LockedPointerData
 var _type: Sendable.Type
 init(
  value: UnsafeMutableRawPointer,
  rawValue: LockedPointerData,
  type: Sendable.Type
 ) {
  self._value = value
  self.rawValue = rawValue
  self._type = type
 }

 init<A>(_ value: inout A) {
  self.init(
   value: &value,
   rawValue:
   LockedPointerData(
    lock: .init(),
    offset:
    MemoryLayout<A>.offset(of: \A.self) ?? 0
   ),
   type: A.self
  )
 }

 func hash(into hasher: inout Hasher) {
  hasher.combine(_value)
 }

 static func == (
  lhs: UnsafeRawLockedPointer,
  rhs: UnsafeRawLockedPointer
 ) -> Bool {
  lhs.hashValue == rhs.hashValue
 }
}

struct LockedPointerData {
 var lock: os_unfair_lock_s
 var offset: Int = 0
 mutating func lockThread() {
  os_unfair_lock_lock(&lock)
 }

 mutating func unlockThread() {
  os_unfair_lock_unlock(&lock)
 }
}

func withUnsafeLockedPointer<A, Result>(
 _ value: inout A,
 _ result: @escaping (UnsafeLockedPointer<A>) -> Result
) -> Result {
 result(UnsafeLockedPointer(&value))
}
