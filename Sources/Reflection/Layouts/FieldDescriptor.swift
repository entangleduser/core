#if canImport(CRuntime)
 import CRuntime
#endif

@_silgen_name("swift_getTypeByMangledNameInContext")
func _getTypeByMangledNameInContext(
 _ name: UnsafePointer<UInt8>,
 _ nameLength: UInt,
 _ genericContext: UnsafeRawPointer?,
 _ genericArguments: UnsafeRawPointer?
) -> Any.Type?

// swiftlint:disable:next line_length
/// https://github.com/apple/swift/blob/f2c42509628bed66bf5b8ee02fae778a2ba747a1/include/swift/Reflection/Records.h#L160
struct FieldDescriptor {
 let mangledTypeNameOffset: Int32
 let superClassOffset: Int32
 let _kind: UInt16
 let fieldRecordSize: Int16
 let numFields: Int32
 let fields: FieldRecord

 var kind: FieldDescriptorKind {
  FieldDescriptorKind(rawValue: _kind)!
 }
}

extension UnsafePointer where Pointee == FieldRecord {
 func fieldName() -> String {
  String(cString: advance(offset: \._fieldName))
 }

 func type(
  genericContext: UnsafeRawPointer?,
  genericArguments: UnsafeRawPointer?
 ) -> Any.Type {
  let typeName = advance(offset: \._mangledTypeName)
  return _getTypeByMangledNameInContext(
   typeName,
   getSymbolicMangledNameLength(typeName),
   genericContext,
   genericArguments?.assumingMemoryBound(to: UnsafeRawPointer?.self)
  )!
 }
}

private func getSymbolicMangledNameLength(_ base: UnsafeRawPointer) -> UInt {
 var end = base
 while let current = Optional(end.load(as: UInt8.self)), current != 0 {
  end += 1
  if current >= 0x1, current <= 0x17 {
   end += 4
  } else if current >= 0x18, current <= 0x1F {
   end += MemoryLayout<Int>.size
  }
 }

 return UInt(end - base)
}

struct FieldRecord {
 let fieldRecordFlags: Int32
 let _mangledTypeName: MetadataOffset<UInt8>
 let _fieldName: MetadataOffset<UInt8>

 var isVar: Bool {
  (fieldRecordFlags & 0x2) == 0x2
 }
}

enum FieldDescriptorKind: UInt16 {
 case `struct`
 case `class`
 case `enum`
 case multiPayloadEnum
 case `protocol`
 case classProtocol
 case objcProtocol
 case objcClass
}
