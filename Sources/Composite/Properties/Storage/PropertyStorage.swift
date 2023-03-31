struct PropertyStorage: PropertyCache {
 var cache: [String: () -> Any] = .empty
 var _parent: UnsafeMutablePointer<Self>?
}
