import Foundation

public extension Collection<URLQueryItem> {
 subscript(_ name: String) -> String? {
  first(where: { $0.name == name })?.value
 }
}

extension URL: ExpressibleByStringLiteral {
 public init(stringLiteral: String) {
  self.init(string: stringLiteral)!
 }
}

extension URL: LosslessStringConvertible {
 public init?(_ description: String) {
  guard let url = URL(string: description) else { return nil }
  self = url
 }
}
