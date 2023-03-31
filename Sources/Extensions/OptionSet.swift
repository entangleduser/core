public struct OptionSetIterator<Set, Element>: IteratorProtocol
where Set: OptionSet, Element: FixedWidthInteger, Set.RawValue == Element {
 private let value: Set
 private lazy var remainingBits = value.rawValue
 private var bitMask: Element = 1

 public init(element: Set) {
  self.value = element
 }

 public mutating func next() -> Set? {
  while remainingBits != 0 {
   defer { bitMask = bitMask &* 2 }
   if remainingBits & bitMask != 0 {
    remainingBits = remainingBits & ~bitMask
    return Set(rawValue: bitMask)
   }
  }
  return nil
 }
}

public extension OptionSet where RawValue: FixedWidthInteger {
 func makeIterator() -> OptionSetIterator<Self, RawValue> {
  OptionSetIterator(element: self)
 }
}
