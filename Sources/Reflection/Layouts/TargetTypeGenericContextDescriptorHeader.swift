struct TargetTypeGenericContextDescriptorHeader {
 let instantiationCache: Int32
 let defaultInstantiationPattern: Int32
 let base: TargetGenericContextDescriptorHeader
}

struct TargetGenericContextDescriptorHeader {
 let numberOfParams: UInt16
 let numberOfRequirements: UInt16
 let numberOfKeyArguments: UInt16
 let numberOfExtraArguments: UInt16
}
