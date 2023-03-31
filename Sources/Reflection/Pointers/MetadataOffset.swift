struct MetadataOffset<Pointee> {
 let offset: Int32

 func apply(to ptr: UnsafeRawPointer) -> UnsafePointer<Pointee> {
  #if arch(wasm32)
   return UnsafePointer<Pointee>(bitPattern: Int(offset))!
  #else
   return ptr.advanced(by: numericCast(offset)).assumingMemoryBound(to: Pointee.self)
  #endif
 }
}

extension MetadataOffset: CustomStringConvertible {
 var description: String {
  "\(offset)"
 }
}
