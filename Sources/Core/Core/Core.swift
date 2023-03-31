@_exported import Foundation

struct Core {}

extension UUID: Infallible {
 public static var defaultValue: Self { Self() }
}
