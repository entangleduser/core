protocol ValueKey: Hashable {
 associatedtype Value
 associatedtype ResolvedValue
 static var resolvedValue: ResolvedValue { get }
}

extension ValueKey {
 static var description: String { String(describing: Self.self) }
 static var customMirror: Mirror {
  Mirror(Self.self, children: [description: resolvedValue])
 }
}

protocol OptionalKey: ValueKey {
 override associatedtype ResolvedValue = Value?
}

extension OptionalKey {
 static var resolvedValue: Value? { nil }
}

protocol DefaultKey: ValueKey where ResolvedValue == Value {
 override associatedtype ResolvedValue = Value
 static var defaultValue: Value { get }
}

extension DefaultKey {
 static var resolvedValue: Value { defaultValue }
}
