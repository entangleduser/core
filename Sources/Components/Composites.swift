public protocol Composite: Expressible {
 associatedtype Component: Expressible
 associatedtype Exponent:
  Numeric & Sendable & ExpressibleByFloatLiteral
  & ExpressibleByIntegerLiteral & Infallible
}

public protocol Deducible: Composite {
 mutating func sink(_ exponent: inout Exponent) async -> Exponent?
}

public protocol Scalable: Composite {
 mutating func scale(
  component: Component, with exponent: inout Exponent
 ) async -> Exponent?
}

public protocol Exponential: Valueable {
 var component: Component { get set }
 var exponent: Exponent { get set }
}

public extension Exponential {
 init(component: Component, exponent: Exponent) {
  self.init()
  self.component = component
  self.exponent = exponent
 }

 init(_ elements: (Component, Exponent)) {
  self.init()
  self.component = elements.0
  self.exponent = elements.1
 }

 init(dictionaryLiteral elements: (Component, Exponent)...) {
  self.init(elements.first!)
 }

 var description: String {
  "\(component) | \(exponent)" +
   (exponent == .defaultValue ? " (default)" : .empty)
 }
}

public extension Exponential where Component: Equatable {
 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.component == rhs.component && lhs.exponent == rhs.exponent
 }
}

/// An expression that is likely to be unique because of it's component symbol and
/// exponent value
/// - Note: `Equatable` by component and exponent, `Hashable` by component
public struct Constraint<Component, Exponent>:
 Exponential, CustomStringConvertible, ExpressibleByDictionaryLiteral where
 Component: Expressible,
 Exponent: Numeric & Sendable & ExpressibleByFloatLiteral & ExpressibleByIntegerLiteral
 & ExpressibleAsZero {
 public init() {}
 public init(component: Component = .defaultValue, exponent: Exponent = .zero) {
  self.component = component
  self.exponent = exponent
 }

 public var component: Component = .defaultValue
 public var exponent: Exponent = .zero
}

extension Constraint: Hashable where Component: Hashable {
 public func hash(into hasher: inout Hasher) {
  hasher.combine(component)
 }
}

extension Constraint: Equatable where Component: Equatable {}

// MARK: - Collections
public protocol Composable: Composite, ExpressibleByArrayLiteral where
 Values.Element: Valueable, Component == Values.Element.Component,
 Exponent == Values.Element.Exponent {
 associatedtype Values: Sequence & ExpressibleByArrayLiteral & Sendable
 var values: Values { get set }
 var count: Int { get }
}

public extension Composable where Values: Collection {
 var count: Int { values.count }
 init(arrayLiteral values: Values) {
  self.init()
  self.values = values
 }
}

/// A unique set of symbols that express a constraint
public struct Void<Values, Component, Exponent>: Deducible where
 Values: SetAlgebra & Sequence & ExpressibleByArrayLiteral & Sendable,
 Component: Expressible & Hashable,
 Exponent:
 Numeric & Sendable & ExpressibleByFloatLiteral
 & ExpressibleByIntegerLiteral & ExpressibleAsZero & Hashable & Comparable,
 Values.Element: Exponential,
 Values.Element.Component == Component, Values.Element.Exponent == Exponent {
 public init() {}
 public var values: Values = .empty
 /// - Note: Changing scale increases or decreses the throughput of the expression
 var scale: Exponent = 1 {
  didSet {
   // refactor values according to scale
   for value in values {
    values.remove(value)
    let factor = value.exponent * scale
    values.insert(
     Values.Element(component: value.component, exponent: value.exponent * factor)
    )
   }
  }
 }

 public mutating func sink(_ initialValue: inout Exponent) async -> Exponent? {
  for value in values.sorted(by: { $0.exponent < $1.exponent }) {
   guard initialValue != .zero else { break }
   guard value.exponent < scale else { continue }
   let projectedValue = value.exponent + initialValue
   guard projectedValue <= scale else {
    initialValue -= projectedValue - scale
    continue
   }
   values.remove(value)
   values.insert(
    Values.Element(component: value.component, exponent: projectedValue)
   )
  }
  return initialValue == .zero ? nil : initialValue
 }

 public mutating func reduce() -> Exponent? {
  let remainder: Exponent = .zero
  return remainder == .zero ? nil : remainder
 }
}

extension Void: Scalable {
 public mutating func scale(
  component: Component, with exponent: inout Exponent
 ) async -> Exponent? {
  guard
   let currentPointer = // must contain this symbol or else
   values.first(where: { $0.component == component })
  else { fatalError() }
  let initialValue = currentPointer.exponent
  guard initialValue != exponent else { return nil }

  var newValue = exponent * initialValue
  let remainder: Exponent? = newValue < scale ? .defaultValue : nil
  if let remainder { newValue -= remainder }
  // remove and replace current component unconditionally
  values.remove(currentPointer)
  values.insert(Values.Element(component: component, exponent: newValue))
  return remainder
 }
}

/// - Note:
/// Assuming all cases are required to represent the relationship between components
public extension Void where
Component: CaseIterable, Exponent: BinaryFloatingPoint {
 init(scale: Exponent = 1) {
  let cases = Component.allCases
  let exponent = scale / Exponent(exactly: Component.allCases.count)!
  self.values = Values(
   cases.map { Values.Element(component: $0, exponent: exponent) }
  )
 }

 init() { self.init(scale: 1) }
}

extension Void: CustomStringConvertible {
 public var description: String {
  values.map { String(describing: $0) }.sorted().joined(separator: "\n")
 }
}

public extension Void where Exponent: Comparable {
 static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.values == rhs.values && lhs.scale == rhs.scale
 }
}
