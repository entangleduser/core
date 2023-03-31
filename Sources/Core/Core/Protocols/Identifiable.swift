#if !canImport(SwiftUI)
 @available(macOS 10.9, *, iOS 9.0, *)
 public protocol Identifiable {
  /// A type representing the stable identity of the entity associated with
  /// an instance.
  associatedtype ID: Hashable
  /// The stable identity of the entity associated with this instance.
  @inlinable
  var id: ID { get }
 }

 public extension Identifiable where Self: AnyObject {
  var id: ObjectIdentifier { ObjectIdentifier(self) }
 }
#endif
