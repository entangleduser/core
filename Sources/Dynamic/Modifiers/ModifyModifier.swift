struct ModifyModifier<Content: Dynamic>: DynamicModifier {
 let modify: (inout Content) -> Void
 func content(_ content: Content) -> Content {
  var copy = content
  modify(&copy)
  return copy
 }
}

extension Dynamic {
 func modify(_ modified: @escaping (inout Self) -> Void) -> Self {
  modifier(ModifyModifier(modify: modified))
 }
}
