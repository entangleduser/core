enum MetadataState: UInt {
 case complete = 0x00
 case nonTransitiveComplete = 0x01
 case layoutComplete = 0x3F
 case abstract = 0xFF
}

private let isBlockingMask: UInt = 0x100

struct MetadataRequest {
 private let bits: UInt

 init(desiredState: MetadataState, isBlocking: Bool) {
  if isBlocking {
   self.bits = desiredState.rawValue | isBlockingMask
  } else {
   self.bits = desiredState.rawValue & ~isBlockingMask
  }
 }
}

struct MetadataResponse {
 let metadata: UnsafePointer<StructMetadata>
 let state: MetadataState
}

@_silgen_name("swift_checkMetadataState")
func _checkMetadataState(_ request: MetadataRequest, _ type: StructMetadata) -> MetadataResponse
