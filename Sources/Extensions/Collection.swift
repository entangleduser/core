#if canImport(Dispatch)
 import Foundation

 // MARK: Transforming
 public extension Collection {
  @inline(__always)
  @_disfavoredOverload func parallelMap<R>(
   _ transform: @escaping (Element) throws -> R
  ) rethrows -> [R] {
   var res: [R] = .empty
   let lock = NSRecursiveLock()
   DispatchQueue.concurrentPerform(iterations: count) { i in
    do {
     lock.lock()
     try res.append(transform(self[index(startIndex, offsetBy: i)]))
     lock.unlock()
    } catch { debugPrint(error.localizedDescription) }
   }
   return res
  }

  @inline(__always) func parallelMap<R>(_ transform: @escaping (Element) throws -> R?) rethrows -> [R] {
   var res: [R?] = .init(repeating: .none, count: count)
   let lock = NSRecursiveLock()
   DispatchQueue.concurrentPerform(iterations: count) { i in
    do {
     lock.lock()
     if let value = try transform(self[index(startIndex, offsetBy: i)]) {
      res[i] = value
     }
     lock.unlock()
    } catch { debugPrint(error.localizedDescription) }
   }
   return res.compactMap { $0 }
  }

  @inline(__always) func parallelFilter(
   _ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
   var res: [Element] = .empty
   let lock = NSRecursiveLock()
   DispatchQueue.concurrentPerform(iterations: count) { i in
    do {
     lock.lock()
     let value = self[index(startIndex, offsetBy: i)]
     if try isIncluded(value) {
      res.append(value)
     }
     lock.unlock()
    } catch { debugPrint(error.localizedDescription) }
   }
   return res
  }

  @inline(__always) func parallelPerform(
   _ transform: (Element) throws -> Void) rethrows {
   let lock = NSRecursiveLock()
   DispatchQueue.concurrentPerform(iterations: count) { i in
    do {
     lock.lock()
     try transform(self[index(startIndex, offsetBy: i)])
     lock.unlock()
    } catch { debugPrint(error.localizedDescription) }
   }
  }
 }
#endif
#if canImport(_Concurrency) || canImport(Concurrency)
 #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  extension Sequence {
   // https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
   @inline(__always) @_disfavoredOverload func map<T>(
    _ transform: @Sendable @escaping (Element) async throws -> T
   ) async rethrows -> [T] where Element: Sendable {
    var values = [T]()

    for element in self {
     try await values.append(transform(element))
    }

    return values
   }

   @inline(__always) @_disfavoredOverload func compactMap<T>(
    _ transform: @Sendable (Element) async throws -> T?
   ) async rethrows -> [T] where T: Sendable, Element: Sendable {
    var values = [T]()

    for element in self {
     guard let value = try await transform(element) else { continue }
     values.append(value)
    }

    return values
   }

   @inline(__always) @_disfavoredOverload func concurrentMap<T>(
    _ transform: @Sendable @escaping (Element) async throws -> T
   ) async throws -> [T] where T: Sendable, Element: Sendable {
    let tasks = map { element in
     Task {
      try await transform(element)
     }
    }
    return try await tasks.map { task in
     try await task.value
    }
   }

   @inline(__always) func concurrentMap<T>(
    _ transform: @Sendable @escaping (Element) async throws -> T?
   ) async throws -> [T] where T: Sendable, Element: Sendable {
    let tasks = map { element in
     Task {
      try await transform(element)
     }
    }
    return try await tasks.compactMap { task in
     try await task.value
    }
   }
  }
 #else
  extension Sequence {
   // https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
   @inline(__always) @_disfavoredOverload func map<T>(
    _ transform: @Sendable @escaping (Element) async throws -> T
   ) async rethrows -> [T] where Element: Sendable {
    var values = [T]()

    for element in self {
     try await values.append(transform(element))
    }

    return values
   }

   @inline(__always) @_disfavoredOverload func compactMap<T>(
    _ transform: @Sendable (Element) async throws -> T?
   ) async rethrows -> [T] where T: Sendable, Element: Sendable {
    var values = [T]()

    for element in self {
     guard let value = try await transform(element) else { continue }
     values.append(value)
    }

    return values
   }

   @inline(__always) @_disfavoredOverload func concurrentMap<T>(
    _ transform: @Sendable @escaping (Element) async throws -> T
   ) async throws -> [T] where T: Sendable, Element: Sendable {
    let tasks = map { element in
     Task {
      try await transform(element)
     }
    }
    return try await tasks.map { task in
     try await task.value
    }
   }

   @inline(__always) func concurrentMap<T>(
    _ transform: @Sendable @escaping (Element) async throws -> T?
   ) async throws -> [T] where T: Sendable, Element: Sendable {
    let tasks = map { element in
     Task {
      try await transform(element)
     }
    }
    return try await tasks.compactMap { task in
     try await task.value
    }
   }
  }
 #endif
#endif

#if canImport(_Concurrency) || canImport(Concurrency)
 #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  public extension RangeReplaceableCollection where Index: Comparable {
   @inline(__always) mutating func dequeue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Void
   ) async where Element: Sendable {
    await withTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { await task(element) }
      }
      await group.next()
      count -= 1
     }
    }
   }

   /// Perform a task queue, limiting to a certain count or number of processors
   @inline(__always) func queue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Void
   ) async where Element: Sendable {
    await withTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { await task(element) }
      }
      await group.next()
      count -= 1
     }
    }
   }

   @inline(__always) mutating func throwingDequeue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Void
   ) async rethrows where Element: Sendable {
    try await withThrowingTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { try await task(element) }
      }
      try await group.next()
      count -= 1
     }
    }
   }

   /// Perform a throwing task queue, limiting to a certain count or number of processors
   @inline(__always) func throwingQueue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Void
   ) async rethrows where Element: Sendable {
    try await withThrowingTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { try await task(element) }
      }
      try await group.next()
      count -= 1
     }
    }
   }

   @discardableResult @inline(__always) mutating func dequeueResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Result
   ) async -> [Result] where Element: Sendable {
    await withTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { await task(element) }
      }
      if let result = await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }

   /// Perform a task queue, returning the accumulated results of the closure
   @inline(__always) @discardableResult func queueResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Result
   ) async -> [Result] where Element: Sendable {
    await withTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { await task(element) }
      }
      if let result = await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }

   @discardableResult @inline(__always) mutating func dequeueThrowingResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Result
   ) async rethrows -> [Result] where Result: Sendable, Element: Sendable {
    try await withThrowingTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { try await task(element) }
      }
      if let result = try await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }

   /// Perform a throwing task queue, returning the accumulated results of the closure
   @inline(__always) @discardableResult func queueThrowingResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Result
   ) async rethrows -> [Result] where Result: Sendable, Element: Sendable {
    try await withThrowingTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { try await task(element) }
      }
      if let result = try await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }
  }
 #else
  public extension RangeReplaceableCollection where Index: Comparable {
   @inline(__always) mutating func dequeue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Void
   ) async where Element: Sendable {
    await withTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { await task(element) }
      }
      await group.next()
      count -= 1
     }
    }
   }

   /// Perform a task queue, limiting to a certain count or number of processors
   @inline(__always) func queue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Void
   ) async where Element: Sendable {
    await withTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { await task(element) }
      }
      await group.next()
      count -= 1
     }
    }
   }

   @inline(__always) mutating func throwingDequeue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Void
   ) async rethrows where Element: Sendable {
    try await withThrowingTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { try await task(element) }
      }
      try await group.next()
      count -= 1
     }
    }
   }

   /// Perform a throwing task queue, limiting to a certain count or number of processors
   @inline(__always) func throwingQueue(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Void
   ) async rethrows where Element: Sendable {
    try await withThrowingTaskGroup(of: Void.self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { try await task(element) }
      }
      try await group.next()
      count -= 1
     }
    }
   }

   @discardableResult @inline(__always) mutating func dequeueResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Result
   ) async -> [Result] where Element: Sendable {
    await withTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { await task(element) }
      }
      if let result = await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }

   /// Perform a task queue, returning the accumulated results of the closure
   @inline(__always) @discardableResult func queueResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async -> Result
   ) async -> [Result] where Element: Sendable {
    await withTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { await task(element) }
      }
      if let result = await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }

   @discardableResult @inline(__always) mutating func dequeueThrowingResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Result
   ) async rethrows -> [Result] where Result: Sendable, Element: Sendable {
    try await withThrowingTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var count: Int = .zero
     while !isEmpty {
      while count < limit, !isEmpty {
       count += 1
       let element = self.removeFirst()
       group.addTask(priority: priority) { try await task(element) }
      }
      if let result = try await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }

   /// Perform a throwing task queue, returning the accumulated results of the closure
   @inline(__always) @discardableResult func queueThrowingResults<Result>(
    limit: Int? = nil,
    priority: TaskPriority = .medium,
    _ task: @Sendable @escaping (Element) async throws -> Result
   ) async rethrows -> [Result] where Result: Sendable, Element: Sendable {
    try await withThrowingTaskGroup(of: Result.self, returning: [Result].self) { group in
     let limit = limit ?? ProcessInfo.processInfo.processorCount
     var results: [Result] = .empty
     var offset = startIndex
     var count: Int = .zero
     while offset < endIndex {
      while count < limit, offset < endIndex {
       count += 1
       let element = self[offset]
       offset = index(after: offset)
       group.addTask(priority: priority) { try await task(element) }
      }
      if let result = try await group.next() { results.append(result); count -= 1 }
     }
     return results
    }
   }
  }
 #endif
#endif
// MARK: Uniquing
public extension RandomAccessCollection where Element: Hashable {
 func unique() -> [Iterator.Element] {
  var seen: Set<Element> = []
  return filter { seen.insert($0).inserted }
 }
}

public extension Array where Element: Hashable {
 @discardableResult mutating func removeDuplicates() -> Self {
  self = unique()
  return self
 }
}

public extension Array where Element: Equatable {
 func unique() -> Self {
  var expression = self
  for element in self {
   while expression.count(for: element) > 1 {
    if let index = expression.firstIndex(where: { $0 == element }) {
     expression.remove(at: index)
    }
   }
  }
  return expression
 }

 @discardableResult mutating func removeDuplicates() -> Self {
  self = unique()
  return self
 }
}

// MARK: Unique Operations
public extension Sequence where Element: Equatable {
 func map(where condition: @escaping (Element) throws -> Bool) rethrows -> [Element]? {
  try compactMap { element in
   try condition(element) ? element : nil
  }.wrapped
 }

 func reduce(where condition: @escaping (Element) throws -> Bool) rethrows -> [Element] {
  try reduce([Element]()) {
   if let last = $0.last, try condition(last), try condition($1) {
    return $0
   }
   return $0 + [$1]
  }
 }

 func reduce(element: Element) -> [Element] {
  reduce([Element]()) {
   if let last = $0.last, last == element, $1 == element {
    return $0
   }
   return $0 + [$1]
  }
 }
}

public extension Sequence where Self: Equatable {
 func isSubset(of sequence: some Sequence<Self>) -> Bool {
  sequence.contains(self)
 }

 static func ~= (lhs: Self, rhs: some Sequence<Self>) -> Bool {
  rhs.contains(lhs)
 }
}

// using reduce to map elements with a given range
public extension Range where Bound: Strideable, Bound.Stride: SignedInteger {
 @inlinable func map<Element>(
  _ element: @escaping () throws -> Element?
 ) rethrows -> [Element] {
  try reduce(into: [Element]()) { results, _ in
   results += [try element()!]
  }
 }
}

// MARK: Sequence

// inserting is like joined but it replaces on condition
// required for converting model strings for using with css in `views.swift`
public extension RangeReplaceableCollection where Element: Equatable {
 @discardableResult
 mutating func insert(
  separator: Element, where condition: @escaping (Element) -> Bool
 ) -> Self {
  let indices = indices.dropFirst().dropLast()
  var inserted = 0

  for index in indices {
   let projectedIndex = self.index(index, offsetBy: inserted)
   guard condition(self[projectedIndex]) else { continue }
   insert(separator, at: projectedIndex)
   // if we insert one, we create an offset that must be compensate
   inserted += 1
  }
  return self
 }

 func inserting(
  separator: Element, where condition: @escaping (Element) -> Bool
 ) -> Self {
  var `self` = self
  return self.insert(separator: separator, where: condition)
 }

 func replacing(
  separator: Element, where condition: @escaping (Element) -> Bool
 ) -> Self {
  Self(
   map { condition($0) ? separator : $0 }
  )
 }
}

public extension RangeReplaceableCollection where Element: Equatable {
 @discardableResult
 mutating func insert(
  separator: Element,
  where condition: @escaping (Element) -> Bool,
  transforming: @escaping (Element) throws -> Element
 ) rethrows -> Self {
  let first = self[startIndex]

  // the first condition must be checked and replaced
  if condition(first) {
   remove(at: startIndex)
   try insert(transforming(first), at: startIndex)
  }

  let indices = indices.dropFirst().dropLast()
  var inserted = 0

  for index in indices {
   let projectedIndex = self.index(index, offsetBy: inserted)
   let element = self[projectedIndex]
   guard condition(element) else { continue }

   remove(at: index)
   try insert(transforming(element), at: index)
   insert(separator, at: projectedIndex)

   inserted += 1
  }
  return self
 }

 func inserting(
  separator: Element,
  where condition: @escaping (Element) -> Bool,
  transforming: @escaping (Element) throws -> Element
 ) rethrows -> Self {
  var `self` = self
  return try self.insert(
   separator: separator, where: condition, transforming: transforming
  )
 }
}

public extension Dictionary {
 @inlinable
 @discardableResult
 mutating func add(_ other: (key: Key, value: Value)) -> Self {
  self[other.key] = other.value
  return self
 }

 @inlinable
 func adding(_ other: (key: Key, value: Value)) -> Self {
  var `self` = self
  return self.add(other)
 }

 @inlinable
 @discardableResult
 static func += (_ self: inout Self, other: (key: Key, value: Value)) -> Self {
  self.add(other)
 }

 @inlinable
 static func + (_ self: Self, other: (key: Key, value: Value)) -> Self {
  self.adding(other)
 }
}

public extension RangeReplaceableCollection where Element: Equatable {
 // an attempt to wrap a collection given a delimiter and limit
 @inlinable func wrapping(
  to count: Int, delimiter: Element
 ) -> [SubSequence] {
  guard self.count > count else { return [self[startIndex ..< endIndex]] }
  var elements = [SubSequence]()
  var counted = 0
  var lastIndex = startIndex
  for index in indices {
   let element = self[index]
   if counted >= count {
    if element == delimiter {
     let newElements =
      self[lastIndex ..< self.index(index, offsetBy: elements.isEmpty ? 1 : 0)]
     elements.append(newElements)
     lastIndex = index
     counted = -1
    }
   }
   counted += 1
  }
  if elements.notEmpty, counted > 0 {
   // remove duplicate subsequence
   // elements.removeLast()
   elements.append(self[index(after: lastIndex) ..< endIndex])
   // elements.append(elements[elements.count - 1].dropLast())
  }
  return elements
 }
}

public extension RangeReplaceableCollection where Element: Equatable {
 /// Removes and returns all elements matching `condition`
 /// This is like `removeAll(where:)` except it returns the removed elements
 @inlinable mutating func drop(
  where condition: @escaping (Element) throws -> Bool
 ) rethrows -> [Element] {
  var elements = [Element]()
  for index in indices where try condition(self[index]) {
   elements.append(self.remove(at: index))
  }
  return elements
 }

 @inlinable func removing(
  where condition: @escaping (Element) throws -> Bool
 ) rethrows -> Self {
  var `self` = self
  try self.removeAll(where: condition)
  return self
 }
}

public extension RangeReplaceableCollection where Element: Equatable {
 /// Groups subsequences of continous elements matching `condition`,
 /// ommiting the other elements and keeping indexes
 @inlinable func grouping(
  where condition: @escaping (Element) throws -> Bool
 ) rethrows -> [SubSequence] {
  var subsequences = [SubSequence]()
  // create capacitance
  var lastIndex: Index?
  for index in indices {
   let element = self[index]
   guard try condition(element) else {
    if let startIndex = lastIndex {
     subsequences.append(self[startIndex ..< index])
     lastIndex = nil
    }
    continue
   }
   lastIndex = index
  }
  return subsequences
 }

 // Removes single outside elements or returns and empty subsequence if
 // the count is less than three
 @inlinable var bracketsRemoved: SubSequence {
  guard count > 2 else { return SubSequence() }
  return self[index(after: startIndex) ..< index(endIndex, offsetBy: -1)]
 }
}

public extension Collection where Element: Equatable {
 @inlinable func count(for element: Element) -> Int {
  reduce(0) { $1 == element ? $0 + 1 : $0 }
 }

 @discardableResult
 @inlinable
 /// Matches sequential elements where the `condition` is true
 func matchingGroups(of element: Element) -> [ArraySlice<Self.Element>] {
  split(whereSeparator: { $0 != element }).removing(where: { $0.count == 1 })
 }

 @inlinable func separating(
  where condition: (Element) throws -> Bool
 ) rethrows -> [SubSequence] {
  try split(whereSeparator: condition) // .removing(where: { $0.count == 1 })
 }

 @inlinable func count(
  where condition: @escaping (Element) throws -> Bool
 ) rethrows -> Int {
  try reduce(0) { try condition($1) ? $0 + 1 : $0 }
 }

 @inlinable func isRecursive(for element: Element) -> Bool {
  count(for: element).isMultiple(of: 2)
 }
}

public extension RangeReplaceableCollection {
 @inlinable
 @discardableResult
 /// Removes elements from the collection if result isn't `nil` and returns all results
 /// Like compact map but removes the original element from the collection
 mutating func invert<Result>(
  _ result: @escaping (Element) throws -> Result?
 ) rethrows -> [Result] {
  var elements = [Result]()
  var count: Int = .zero
  var removed: Int = .zero
  var offset = startIndex
  for element in self {
   if let newValue = try result(element) {
    elements.append(newValue)
    remove(at: index(offset, offsetBy: -removed))
    removed += 1
   }
   count += 1
   offset = index(startIndex, offsetBy: count)
  }
// can return the difference
//  try self.removeAll(
//   where: {
//    if let newValue = try result($0) {
//     elements.append(newValue)
//     return true
//    } else {
//     return false
//    }
//   }
//  )
  return elements
 }
}

/* public extension BidirectionalCollection
  where Self: RangeReplaceableCollection, Self: Equatable,
  Element: Hashable, SubSequence: Equatable {
  private func match(
   into subsequences: inout [SubSequence?], with sequence: SubSequence
  ) {
   switch sequence.count {
    case 1: subsequences.append(nil)
    case 2: subsequences.append(SubSequence())
    default: subsequences.append(sequence)
   }
  }

  func components(for element: Element) -> (braces: [SubSequence], guts: [SubSequence])? {
   let braces = separating(where: { $0 != element })
   guard braces.count > 1 else { return nil }

   return (braces, separating(where: { $0 == element }))
  }

  func braces(for element: Element) -> [(lhs: SubSequence, SubSequence, rhs: SubSequence)]? {
   guard let components = components(for: element) else { return nil }
   let guts = components.1
   let braces = components.0
   return (0 ..< guts.count).map { index in
    (braces[index], guts[index], braces[index + 1])
   }
  }
 }
 */
