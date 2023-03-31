struct ReflectionModifier<Content: Dynamic>: DynamicModifier {
 let reflect: (Content) -> Void
 func content(_ content: Content) -> Content {
  defer { reflect(content) }
  return content
 }
}

extension Dynamic {
 func reflect(_ reflected: @escaping (Self) -> Void) -> Self {
  modifier(ReflectionModifier(reflect: reflected))
 }

 func reflectTask(
  _ priority: TaskPriority = .medium,
  _ reflected: @Sendable @escaping (Self) async -> Void
 ) -> Self {
  modifier(
   ReflectionModifier(
    reflect: { `self` in Task(priority: priority, operation: { await reflected(self) }) }
   )
  )
 }
}
