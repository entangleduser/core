extension UnsafePointer: ExpressibleByNilLiteral {
 public init(nilLiteral: ()) {
  self.init(OpaquePointer(UnsafeMutablePointer<Never>.allocate(capacity: 0)))
 }
}

extension UnsafeRawBufferPointer: ExpressibleByNilLiteral {
 public init(nilLiteral: ()) {
  self.init(start: nil, count: 0)
 }
}

extension UnsafeMutableRawBufferPointer: ExpressibleByNilLiteral {
 public init(nilLiteral: ()) {
  self.init(mutating: nil)
 }
}

extension UnsafeMutablePointer: ExpressibleByNilLiteral {
 public init(nilLiteral: ()) {
  self.init(mutating: UnsafePointer<Pointee>(nilLiteral: ()))
 }
}
