public protocol KeyIdentifiable {
 /// A type representing the stable identity of the entity associated with
 /// an instance.
 associatedtype Key: Hashable
 /// The stable identity of the entity associated with this instance.
 var key: Key { get }
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension KeyIdentifiable where Self: Identifiable {
  @inlinable var id: Key { key }
 }
#else
 public extension KeyIdentifiable where Self: Identifiable {
  @inlinable var id: Key { key }
 }
#endif
