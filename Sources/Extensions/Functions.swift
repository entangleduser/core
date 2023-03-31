import struct Foundation.Date

public protocol TimerProtocol: CustomStringConvertible {
 var fireDate: Date { get nonmutating set }
 var endDate: Date { get nonmutating set }
 var invalidationDate: Date { get nonmutating set }
 func fire()
 func end()
 func invalidate()
 static var `default`: Self! { get set }
 init()
 init(
  repeats: Bool,
  count: Int,
  _ closure: @escaping (Self) throws -> Void
 ) throws
 init(
  repeats: Bool,
  count: Int,
  _ closure: @escaping (Self) async throws -> Void
 ) async throws
}

public extension TimerProtocol {
 @_transparent
 @discardableResult
 init(
  repeats: Bool = false,
  count: Int = 2,
  _ closure: @escaping (Self) throws -> Void
 ) throws {
  self.init()
  try self.time(repeats: repeats, count: count, closure)
 }

 init(
  repeats: Bool,
  count: Int,
  _ closure: @escaping (Self) async throws -> Void
 ) async throws {
  self.init()
  try await self.time(repeats: repeats, count: count, closure)
 }

 @_transparent
 func time(
  repeats: Bool = false,
  count: Int = 2,
  _ closure: @escaping (Self) throws -> Void
 ) rethrows {
  func execute() throws {
   defer { self.end() }
   self.fire()
   try closure(self)
  }

  if repeats {
   let count = (0 ..< count)
   guard !count.isEmpty else { return }
   for _ in count { try execute() }
  } else { try execute() }
 }

 @_transparent
 func time(
  repeats: Bool = false,
  count: Int = 2,
  _ closure: @escaping (Self) async throws -> Void
 ) async rethrows {
  func execute() async throws {
   defer { self.end() }
   self.fire()
   try await closure(self)
  }

  if repeats {
   let count = (0 ..< count)
   guard !count.isEmpty else { return }
   for _ in count { try await execute() }
  } else { try await execute() }
 }

// @_transparent
// func time(
//  repeats: Bool = false,
//  count: Int = 2,
//  _ closure: @escaping (Self) async -> Void
// ) async {
//  func execute() async {
//   defer { self.end() }
//   self.fire()
//   await closure(self)
//  }
//
//  if repeats {
//   let count = (0 ..< count)
//   guard !count.isEmpty else { return }
//   for _ in count { await execute() }
//  } else { await execute() }
// }

// @_transparent
// func timeResult<A>(
//  _ closure: @escaping (Self) -> A
// ) -> A {
//  defer { self.end() }
//  self.fire()
//  return closure(self)
// }
//
 @_transparent
 func timeResult<A>(
  _ closure: @escaping (Self) throws -> A
 ) rethrows -> A {
  defer { self.end() }
  self.fire()
  return try closure(self)
 }

 @_transparent
 func timeResult<A>(
  _ closure: @escaping (Self) async throws -> A
 ) async rethrows -> A {
  defer { self.end() }
  self.fire()
  return try await closure(self)
 }

 @_transparent
 nonmutating func fire() { self.fireDate = .init() }
 @_transparent
 nonmutating func end() { self.endDate = .init() }
 @_transparent
 nonmutating func invalidate() {
  self.fireDate = .distantPast
  self.endDate = .distantFuture
  self.invalidationDate = .init()
 }

 @_transparent
 var elapsed: Double { Date().timeIntervalSince(self.fireDate) }
 @_transparent
 var elapsedTime: String { String(format: "%.4f", self.elapsed) }
 @_transparent
 var duration: Double { self.endDate.timeIntervalSince(self.fireDate) }
 @_transparent
 var description: String { elapsedTime }
}

public struct StaticTimer: TimerProtocol {
 public init() {}
 public static var `default`: Self! = Self()
 public var _fireDate: Date = .init()
 public var _endDate: Date = .distantFuture
 public var _invalidationDate: Date = .distantFuture
 @_transparent
 public var fireDate: Date {
  get { Self.default._fireDate }
  nonmutating set { Self.default._fireDate = newValue }
 }

 @_transparent
 public var endDate: Date {
  get { Self.default._endDate }
  nonmutating set { Self.default._endDate = newValue }
 }

 @_transparent
 public var invalidationDate: Date {
  get { Self.default._invalidationDate }
  nonmutating set { Self.default._invalidationDate = newValue }
 }
}

public final class ClassTimer: TimerProtocol {
 public init() {}
 public static var `default`: ClassTimer! = ClassTimer()
 public var fireDate: Date = .init()
 public var endDate: Date = .init()
 public var invalidationDate: Date = .init()
 deinit { print("ClassTimer deinitialized") }
}

@_transparent
public func withTimer(
 _ timer: StaticTimer = .default,
 repeats: Bool = false,
 count: Int = 0,
 _ closure: @escaping (StaticTimer) throws -> Void
) rethrows {
 try timer.time(repeats: repeats, count: count, closure)
}

@_transparent
public func withTimer(
 _ timer: StaticTimer = .default,
 repeats: Bool = false,
 count: Int = 0,
 _ closure: @escaping (StaticTimer) async throws -> Void
) async rethrows {
 try await timer.time(repeats: repeats, count: count, closure)
}

@_transparent
@discardableResult
public func withTimedResult<A>(
 _ timer: StaticTimer = .default,
 _ closure: @escaping (StaticTimer) throws -> A
) rethrows -> A {
 try timer.timeResult(closure)
}

@_transparent
@discardableResult
public func withTimedResult<A>(
 _ timer: StaticTimer = .default,
 _ closure: @escaping (StaticTimer) async throws -> A
) async rethrows -> A {
 try await timer.timeResult(closure)
}

@_transparent
public func withReferenceTimer(
 _ timer: ClassTimer = .default,
 repeats: Bool = false,
 count: Int = 0,
 _ closure: @escaping (ClassTimer) throws -> Void
) rethrows {
 try timer.time(repeats: repeats, count: count, closure)
}

@_transparent
public func withReferenceTimer(
 _ timer: ClassTimer = .default,
 repeats: Bool = false,
 count: Int = 0,
 _ closure: @escaping (ClassTimer) async throws -> Void
) async rethrows {
 try await timer.time(repeats: repeats, count: count, closure)
}

@_transparent
public func withTask(
 after nanoseconds: Double, _ action: @escaping () throws -> Void = {}
) rethrows {
 Task {
  try await Task.sleep(nanoseconds: UInt64(nanoseconds))
  try action()
 }
}

@_transparent
public func withTask(
 after nanoseconds: Double,
 _ action: @escaping () async throws -> Void = {}
) async rethrows {
 try! await Task.sleep(nanoseconds: UInt64(nanoseconds))
 try await action()
}

@_transparent
@discardableResult
public func withTask<Result>(
 after nanoseconds: Double,
 _ action: @escaping () throws -> Result
) rethrows -> Result {
 Task { try await Task.sleep(nanoseconds: UInt64(nanoseconds)) }
 return try action()
}

@_transparent
@discardableResult
public func withTask<Result>(
 after nanoseconds: Double,
 _ action: @escaping () async throws -> Result
) async rethrows -> Result {
 try! await Task.sleep(nanoseconds: UInt64(nanoseconds))
 return try await action()
}
