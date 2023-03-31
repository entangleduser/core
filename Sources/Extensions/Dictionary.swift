public extension Dictionary {
 mutating func append(contentsOf other: Self) {
  for (key, value) in other { self[key] = value }
 }

 func appending(contentsOf other: Self) -> Self {
  var `self` = self
  self.append(contentsOf: other)
  return self
 }

 static func + (lhs: Self, rhs: Self) -> Self { lhs.appending(contentsOf: rhs) }
 static func += (lhs: inout Self, rhs: Self) { lhs.append(contentsOf: rhs) }
}
