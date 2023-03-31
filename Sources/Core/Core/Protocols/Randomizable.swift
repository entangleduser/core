public protocol Randomizable: Infallible {
 mutating func randomize()
}

public extension Randomizable {
 static var random: Self {
  var `self` = Self.defaultValue
  self.randomize()
  return self
 }
}

public protocol MutableIdentity: Identifiable {
 override var id: ID { get set }
}

public extension Infallible where Self: MutableIdentity {
 init(identifying id: ID) {
  self = .defaultValue
  self.id = id
 }
}

public extension Randomizable where Self: MutableIdentity {
 static func random(_ id: ID) -> Self {
  var random = Self(identifying: id)
  random.randomize()
  return random
 }
}
