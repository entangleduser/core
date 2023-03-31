public struct StructMetadata {
 let pointer: UnsafePointer<StructMetadataLayout>

 public func toTypeInfo() -> TypeInfo {
  TypeInfo(metadata: self)
 }

 var genericArgumentOffset: Int {
  // default to 2. This would put it right after the type descriptor which is valid
  // for all types except for classes
  2
 }

 var isGeneric: Bool {
  (pointer.pointee.typeDescriptor.pointee.flags & 0x80) != 0
 }

 public func mangledName() -> String {
  let base = pointer.pointee.typeDescriptor
  let offset = MemoryLayout<StructTypeDescriptor>
   .offset(of: \StructTypeDescriptor.mangledName)!
  return String(cString: base.pointee.mangledName.apply(to: base.raw.advanced(by: offset)))
 }

 func numberOfFields() -> Int {
  Int(pointer.pointee.typeDescriptor.pointee.numberOfFields)
 }

 func fieldOffsets() -> [Int] {
  pointer.pointee.typeDescriptor.pointee
   .offsetToTheFieldOffsetVector
   .vector(metadata: pointer.raw.assumingMemoryBound(to: Int.self), n: numberOfFields())
   .map(numericCast)
 }

 public func properties() -> [PropertyInfo] {
  let offsets = fieldOffsets()
  let fieldDescriptor = pointer.pointee.typeDescriptor.advance(offset: \.fieldDescriptor)
  let genericVector = genericArgumentVector()

  let fields = fieldDescriptor.vector(at: \.fields)
  return (0 ..< numberOfFields()).map { i in
   let record = fields.advanced(by: i)

   return PropertyInfo(
    name: record.fieldName(),
    type: record.type(
     genericContext: pointer.pointee.typeDescriptor,
     genericArguments: genericVector
    ),
    isVar: record.pointee.isVar,
    offset: offsets[i],
    ownerType: type
   )
  }
 }

 func genericArguments() -> UnsafeBufferPointer<Any.Type> {
  guard isGeneric else { return .init(start: nil, count: 0) }

  let count = pointer.pointee
   .typeDescriptor
   .pointee
   .genericContextHeader
   .base
   .numberOfParams
  return genericArgumentVector().buffer(n: Int(count))
 }

 func genericArgumentVector() -> UnsafePointer<Any.Type> {
  pointer
   .raw.advanced(by: genericArgumentOffset * MemoryLayout<UnsafeRawPointer>.size)
   .assumingMemoryBound(to: Any.Type.self)
 }

 public var type: Any.Type {
  unsafeBitCast(pointer, to: Any.Type.self)
 }

 public var kind: Kind {
  Kind(flag: pointer.pointee._kind)
 }

 var size: Int {
  valueWitnessTable.pointee.size
 }

 public var alignment: Int {
  (valueWitnessTable.pointee.flags & ValueWitnessFlags.alignmentMask) + 1
 }

 var stride: Int {
  valueWitnessTable.pointee.stride
 }

 /// The ValueWitnessTable for the type.
 /// A pointer to the table is located one pointer sized word behind the metadata pointer.
 var valueWitnessTable: UnsafePointer<ValueWitnessTable> {
  pointer
   .raw
   .advanced(by: -MemoryLayout<UnsafeRawPointer>.size)
   .assumingMemoryBound(to: UnsafePointer<ValueWitnessTable>.self)
   .pointee
 }
}

public extension StructMetadata {
 init(type: Any.Type) {
  self = Self(pointer: unsafeBitCast(type, to: UnsafePointer<StructMetadataLayout>.self))
  assert(
   _checkMetadataState(
    .init(desiredState: .layoutComplete, isBlocking: false),
    self
   ).state.rawValue < MetadataState.layoutComplete.rawValue,
   """
   Struct metadata for \(type) is in incomplete state, \
   proceeding would result in an undefined behavior.
   """
  )
 }
}
