struct RelativeVectorPointer<Offset: FixedWidthInteger, Pointee> {
 let offset: Offset
 func vector(metadata: UnsafePointer<Int>, n: Int) -> UnsafeBufferPointer<Pointee> {
  metadata.advanced(by: numericCast(offset))
   .raw.assumingMemoryBound(to: Pointee.self)
   .buffer(n: n)
 }
}
