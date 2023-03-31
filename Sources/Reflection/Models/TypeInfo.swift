public struct TypeInfo {
 public let kind: Kind
 public let name: String
 public let type: Any.Type
 public let mangledName: String
 public let properties: [PropertyInfo]
 public let size: Int
 public let alignment: Int
 public let stride: Int
 public let genericTypes: [Any.Type]

 init(metadata: StructMetadata) {
  self.kind = metadata.kind
  self.name = String(describing: metadata.type)
  self.type = metadata.type
  self.size = metadata.size
  self.alignment = metadata.alignment
  self.stride = metadata.stride
  self.properties = metadata.properties()
  self.mangledName = metadata.mangledName()
  self.genericTypes = Array(metadata.genericArguments())
 }

 public func property(named: String) -> PropertyInfo? {
  properties.first(where: { $0.name == named })
 }
}

public func typeInfo(of type: Any.Type) -> TypeInfo? {
 guard Kind(type: type) == .struct else {
  return nil
 }

 return StructMetadata(type: type).toTypeInfo()
}
