typealias FieldTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<Int>

struct StructTypeDescriptor {
 let flags: Int32
 let parent: Int32
 let mangledName: MetadataOffset<CChar>
 let accessFunctionPtr: MetadataOffset<UnsafeRawPointer>
 let fieldDescriptor: MetadataOffset<FieldDescriptor>
 let numberOfFields: Int32
 let offsetToTheFieldOffsetVector: RelativeVectorPointer<Int32, Int32>
 let genericContextHeader: TargetTypeGenericContextDescriptorHeader
}
