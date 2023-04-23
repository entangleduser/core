#if !os(macOS) && !os(iOS) && !os(watchOS) && !os(tvOS)
public typealias AnyIdentifiable = any Identifiable
 public protocol Identifiable<ID> {
  /// A type representing the stable identity of the entity associated with
  /// an instance.
  associatedtype ID: Hashable

  /// The stable identity of the entity associated with this instance.
  var id: Self.ID { get }
 }

 public extension Identifiable where Self: AnyObject {
  /// The stable identity of the entity associated with this instance.
  var id: ObjectIdentifier { ObjectIdentifier(self) }
 }

#else
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public typealias AnyIdentifiable = any Identifiable
#endif
