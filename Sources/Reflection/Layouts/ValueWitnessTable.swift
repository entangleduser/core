struct ValueWitnessTable {
 let initializeBufferWithCopyOfBuffer: UnsafeRawPointer
 let destroy: UnsafeRawPointer
 let initializeWithCopy: UnsafeRawPointer
 let assignWithCopy: UnsafeRawPointer
 let initializeWithTake: UnsafeRawPointer
 let assignWithTake: UnsafeRawPointer
 let getEnumTagSinglePayload: UnsafeRawPointer
 let storeEnumTagSinglePayload: UnsafeRawPointer
 let size: Int
 let stride: Int
 let flags: Int
}

enum ValueWitnessFlags {
 static let alignmentMask = 0x0000_FFFF
 static let isNonPOD = 0x0001_0000
 static let isNonInline = 0x0002_0000
 static let hasExtraInhabitants = 0x0004_0000
 static let hasSpareBits = 0x0008_0000
 static let isNonBitwiseTakable = 0x0010_0000
 static let hasEnumWitnesses = 0x0020_0000
}
