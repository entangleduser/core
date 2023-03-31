func metadataPointer(type: Any.Type) -> UnsafePointer<Int> {
 unsafeBitCast(type, to: UnsafePointer<Int>.self)
}

func metadata(of type: Any.Type) -> StructMetadata {
 guard Kind(type: type) == .struct else {
  fatalError("\(type) must be a struct.")
 }
 return StructMetadata(type: type)
}
