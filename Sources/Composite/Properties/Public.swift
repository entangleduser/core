protocol SourceBindable {
 associatedtype Index: Hashable
 var bindings: [Index: UnsafeMutableRawBufferPointer] { get set }
}

extension SourceBindable {
 subscript(_ index: Index) -> UnsafeMutableRawBufferPointer? {
  get { bindings[index] }
  set { bindings[index] = newValue }
 }
}

extension SourceBindable where Index == String {
 subscript(_ key: some CustomStringConvertible) -> UnsafeMutableRawBufferPointer? {
  get { bindings[key.description] }
  set { bindings[key.description] = newValue }
 }
}
