import Foundation

public extension JSONEncoder {
 convenience init(configuration: @escaping (Self) -> Void) {
  self.init()
  configuration(self)
 }
}

public extension JSONDecoder {
 convenience init(configuration: @escaping (Self) -> Void) {
  self.init()
  configuration(self)
 }
}

#if canImport(CodableCSV)
 import CodableCSV

 public protocol CSVCodable: CSVEncodable & CSVDecodable & AutoCodable {}
 public protocol CSVDecodable: AutoDecodable {}
 public protocol CSVEncodable: AutoEncodable {}

 public extension CSVDecodable {
  static var decoder: CSVDecoder { CSVDecoder() }
 }

 public extension CSVEncodable {
  static var encoder: CSVEncoder { CSVEncoder() }
 }
#endif
// extension TopLevelEncoder {
// init(transform: @escaping (Self) -> Self) -> Se {
//  self.init()
//  tranform(self)
// }
// }
// public extension TopLevelDecoder {
// func decode<T>(
//  _ type: T.Type,
//  collec array: [Input]
// ) throws -> [T] where T: Decodable {
//  try array.map { try self.decode(type, from: $0) }
// }
// }
//
// public extension TopLevelEncoder {
// func encode<T>(
//  collection: A<T>
// ) throws -> [Output] where T: Encodable {
//  try set.map { try self.encode($0) }
// }
// }
