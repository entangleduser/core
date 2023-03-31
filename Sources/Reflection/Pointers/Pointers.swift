func withValuePointer<Value, Result>(
 of value: inout Value,
 _ body: (UnsafeMutableRawPointer) -> Result
) -> Result {
 let kind = Kind(type: Value.self)

 switch kind {
 case .struct:
  return withUnsafePointer(to: &value) { body($0.mutable.raw) }
 case .existential:
  return withExistentialValuePointer(of: &value, body)
 default:
  fatalError()
 }
}

func withExistentialValuePointer<Result>(
 of value: inout some Any,
 _ body: (UnsafeMutableRawPointer) -> Result
) -> Result {
 withUnsafePointer(to: &value) {
  let container = $0
   .withMemoryRebound(to: ExistentialContainer.self, capacity: 1) { $0.pointee }
  let info = metadata(of: container.type)
  if info.kind == .class || info.size > ExistentialContainerBuffer.size() {
   let base = $0
    .withMemoryRebound(to: UnsafeMutableRawPointer.self, capacity: 1) { $0.pointee }
   if info.kind == .struct {
    return body(base.advanced(by: existentialHeaderSize))
   } else {
    return body(base)
   }
  } else {
   return body($0.mutable.raw)
  }
 }
}

var existentialHeaderSize: Int {
 if is64Bit {
  return 16
 } else {
  return 8
 }
}

var is64Bit: Bool {
 MemoryLayout<Int>.size == 8
}
