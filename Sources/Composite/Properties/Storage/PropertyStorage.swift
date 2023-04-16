public struct PropertyStorage: PropertyCache {
 public var _parent: UnsafeMutablePointer<Self>?
 public var cache: [String: () -> Any] = .empty
}
