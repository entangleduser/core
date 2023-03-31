extension UnsafePointer {
 var raw: UnsafeRawPointer {
  UnsafeRawPointer(self)
 }

 var mutable: UnsafeMutablePointer<Pointee> {
  UnsafeMutablePointer<Pointee>(mutating: self)
 }

 func buffer(n: Int) -> UnsafeBufferPointer<Pointee> {
  UnsafeBufferPointer(start: self, count: n)
 }

 func vector<T>(at keyPath: KeyPath<Pointee, T>) -> UnsafePointer<T> {
  let offset = MemoryLayout<Pointee>.offset(of: keyPath)!
  return raw.advanced(by: offset).assumingMemoryBound(to: T.self)
 }

 func advance<T>(offset keyPath: KeyPath<Pointee, MetadataOffset<T>>) -> UnsafePointer<T> {
  let offset = MemoryLayout<Pointee>.offset(of: keyPath)!
  return pointee[keyPath: keyPath].apply(to: raw.advanced(by: offset))
 }
}

extension UnsafePointer where Pointee: Equatable {
 func advance(to value: Pointee) -> UnsafePointer<Pointee> {
  var pointer = self
  while pointer.pointee != value {
   pointer = pointer.advanced(by: 1)
  }
  return pointer
 }
}

extension UnsafeMutablePointer {
 var raw: UnsafeMutableRawPointer {
  UnsafeMutableRawPointer(self)
 }
}
