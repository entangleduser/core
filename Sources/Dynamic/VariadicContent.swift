struct ForEach<Data, ID, Result>: @unchecked Sendable, Dynamic
where Data: RandomAccessCollection & Sendable, ID: Hashable & Sendable, Result: Dynamic {
 var data: Data
 var result: @Sendable (Data.Element) -> Result
 var id: KeyPath<Data.Element, ID>
 init(
  _ data: Data, id: KeyPath<Data.Element, ID>,
  result: @Sendable @escaping (Data.Element) -> Result
 ) {
  self.data = data
  self.result = result
  self.id = id
 }
}

extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
 init(_ data: Data, result: @Sendable @escaping (Data.Element) -> Result) {
  self.init(data, id: \.id, result: result)
 }
}

// MARK: Infrastructure
protocol RootDynamic: Sendable {}
extension DynamicArray: Dynamic
where Root: RootDynamic, Content: Dynamic {}

protocol ContentRoot: RootDynamic {
 associatedtype Content: Dynamic
 @DynamicBuilder func content(_ elements: DynamicElements) -> Content
}

struct DynamicElements {
 var elements: [Element]
 init(_ components: [any Dynamic]) {
  self.elements = components.enumerated().map { Element($0.element, $0.offset) }
 }
}

struct DynamicArray<Root, Content: Sendable> where Root: RootDynamic {
 var root: Root
 var content: Content

 init(root: Root, content: Content) {
  self.root = root
  self.content = content
 }

 @inlinable
 init(_ root: Root, @DynamicBuilder content: () -> Content) {
  self.root = root
  self.content = content()
 }
}

extension DynamicElements: RandomAccessCollection {
 typealias Index = Int
 typealias Indices = Range<Int>
 typealias Iterator = IndexingIterator<Self>
 typealias SubSequence = Slice<Self>

 var startIndex: Int { elements.startIndex }
 var endIndex: Int { elements.endIndex }
 subscript(index: Int) -> Element { elements[index] }

 struct Element: Dynamic, Identifiable {
  init(_ element: some Dynamic, _ id: some Hashable) {
   self.any = element
   self.id = AnyHashable(id)
  }

  let any: any Dynamic
  var id: AnyHashable
  func id<ID>(as _: ID.Type = ID.self) -> ID? where ID: Hashable { id.base as? ID }
  var content: some Dynamic { any }
 }
}

extension DynamicElements: Dynamic {
 var content: some Dynamic { ForEach(elements, result: { $0 }) }
}

extension AnyHashable: @unchecked Sendable {}

protocol GroupDynamic {}
struct DynamicGroup<Content: Dynamic>: Dynamic {
 let content: Content
 init(@DynamicBuilder content: () -> Content) {
  self.content = content()
 }
}

// extension Dynamic {
// func id<ID: Hashable>(_ id: ID) -> some Dynamic {
// }
// }
