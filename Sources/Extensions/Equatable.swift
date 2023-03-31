public extension Equatable {
 @_transparent
 static func == (lhs: Self?, rhs: Self) -> Bool {
  guard let lhs else { return false }
  return lhs == rhs
 }
}

public extension Optional where Wrapped: Sequence, Wrapped.Element: Equatable {
 func contains(optional element: Wrapped.Element?) -> Bool {
  guard let element, let sequence = self else { return false }
  return sequence.contains(element)
 }
}
