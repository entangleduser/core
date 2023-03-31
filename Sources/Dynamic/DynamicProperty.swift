import class Atomics.ManagedAtomic

protocol DynamicProperty: Sendable {
 mutating func update()
}

/// A property that updates an optional reference after mutating
protocol StaticProperty: DynamicProperty {
 var _reference: UniqueReference<StaticPropertyStorage>.Weak? { get mutating set }
 var _offset: ManagedAtomic<Int>? { get mutating set }
}

extension StaticProperty {
 var offset: Int? {
  _offset?.load(ordering: .sequentiallyConsistent)
 }

 var reference: StaticPropertyStorage? {
  get { _reference?.wrappedValue }
  set { _reference?.wrappedValue = newValue }
 }

 func update() { self.reference?.update(self) }
}

protocol DefaultProperty: DynamicProperty {
 associatedtype Wrapped
 var defaultValue: Wrapped? { get set }
}
