struct TaskModifier<Content: Dynamic>: DynamicModifier {
 typealias ModifiedContent = Content
 let priority: TaskPriority
 let operation: @Sendable () async -> Void
 func content(_ content: Content) -> ModifiedContent {
  Task(priority: priority, operation: operation)
  return content
 }
}

extension Dynamic {
 func task(
  priority: TaskPriority = .medium, _ perform: @Sendable @escaping () async -> Void
 ) -> Self {
  modifier(TaskModifier(priority: priority, operation: perform))
 }
}
