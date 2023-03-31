protocol DynamicModifier {
 associatedtype Content: Dynamic
 associatedtype ModifiedContent: Dynamic
 func content(_ content: Content) -> ModifiedContent
}

extension Dynamic {
 func modifier<A: DynamicModifier>(_ a: A) -> A.ModifiedContent
 where A.Content == Self { a.content(self) }
}
