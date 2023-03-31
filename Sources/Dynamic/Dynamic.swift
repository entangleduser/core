import Reflection
protocol Dynamic: Sendable {
 associatedtype Contents: Dynamic
 var content: Contents { get }
}

extension Dynamic {
 typealias Storage = PropertyStorage
 typealias Projection = Object<Self>
 typealias Values = DynamicValues

// var unwrapped: any Dynamic {
//  if let any = self as? AnyDynamic { return any.value as! any Dynamic }
//  else { return self }
// }

 func resolve(_ values: inout Values) -> any Dynamic {
  if let modifier = content as? (any EnvironmentModifier) {
   modifier.modify(&values)
   if content is Never { return modifier.content }
   else { return modifier.content.resolve(&values) }
  } else { return content }
 }

 var metadata: StructMetadata { StructMetadata(type: Self.self) }
 var mirror: Mirror { Mirror(reflecting: self) }
 var identifier: ObjectIdentifier { ObjectIdentifier(Self.self) }
}

struct PropertyIdentifier: Hashable {
 init(_ type: Sendable.Type, _ offset: Int) {
  self.type = type
  self.offset = offset
 }

 let type: Sendable.Type
 let offset: Int
 var reflection: String { String(reflecting: type) }

 static func == (lhs: Self, rhs: Self) -> Bool { lhs.hashValue == rhs.hashValue }
 public func hash(into hasher: inout Hasher) {
  hasher.combine(reflection)
  hasher.combine(offset)
 }
}

extension PropertyInfo: Hashable {
 var id: PropertyIdentifier { PropertyIdentifier(type, offset) }
 public static func == (lhs: Self, rhs: Self) -> Bool { lhs.hashValue == rhs.hashValue }
 public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension StructMetadata: Hashable {
 var id: PropertyIdentifier { PropertyIdentifier(type, alignment) }
 public func hash(into hasher: inout Hasher) {
  hasher.combine(id)
  hasher.combine(alignment)
 }

 public static func == (lhs: StructMetadata, rhs: StructMetadata) -> Bool {
  lhs.hashValue == rhs.hashValue
 }
}

// MARK: Conformances

extension Dynamic where Contents == Never { var content: Never { fatalError() } }
extension Never { typealias Contents = Never }
extension Never: Dynamic {}
extension Optional: Dynamic where Wrapped: Dynamic {
 @DynamicBuilder var content: some Dynamic {
  if let content = self { content }
  else { EmptyDynamic() }
 }
}

struct EmptyDynamic: Dynamic {}

protocol AnyOptional {
 var value: Any? { get }
}

extension Optional: AnyOptional {
 var value: Any? {
  switch self {
  case let .some(value): return value
  case .none: return nil
  }
 }
}

// MARK: Values
struct DynamicValues {
 var values: [String: Sendable] = .empty
 subscript<A: ValueKey>(_ type: A.Type) -> A.ResolvedValue {
  get { values[type.description] as? A.ResolvedValue ?? A.resolvedValue }
  set { values[type.description, default: A.resolvedValue] = newValue }
 }
}

extension DynamicValues: ResolvedValues {
 static var defaultValues: [String: Sendable] {
  [IsEnabledKey.description: IsEnabledKey.defaultValue]
 }
}

extension DynamicValues: CustomReflectable, CustomStringConvertible {}

struct IsEnabledKey: DefaultKey {
 static let defaultValue = true
}

extension DynamicValues {
 var isEnabled: Bool {
  get { self[IsEnabledKey.self] }
  set { self[IsEnabledKey.self] = newValue }
 }
}
