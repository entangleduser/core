import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol JSONCodable: JSONEncodable & JSONDecodable & AutoCodable {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol JSONDecodable: AutoDecodable {}
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol JSONEncodable: AutoEncodable {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension JSONCodable {
 subscript(dynamicMember key: String) -> Any? {
  get { dictionary[key] }
  mutating set {
   var dictionary = dictionary
   if dictionary.contains(where: { $0.key == key }) {
    dictionary[key] = newValue
   } else {
    for key in Self.members.keys where dictionary.keys.contains(key) {
     dictionary[key] = newValue
    }
   }
   do { self = try Self(dictionary) }
   catch { fatalError() }
  }
 }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension JSONEncodable {
 static var encoder: JSONEncoder { JSONEncoder() }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension JSONDecodable {
 static var decoder: JSONDecoder { JSONDecoder() }
 init(_ dictionary: [String: Any]) throws {
  let data =
   try JSONSerialization.data(
    withJSONObject: dictionary, options: [.fragmentsAllowed]
   )
  self = try Self.decoder.decode(Self.self, from: data)
 }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol PlistCodable: PlistEncodable & PlistDecodable & AutoCodable {}
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol PlistDecodable: AutoDecodable {}
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol PlistEncodable: AutoEncodable {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension PlistEncodable {
 static var encoder: PropertyListEncoder { PropertyListEncoder() }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension PlistDecodable {
 static var decoder: PropertyListDecoder { PropertyListDecoder() }
 init(_ dictionary: [String: Any]) throws {
  let data =
   try PropertyListSerialization
    .data(fromPropertyList: dictionary, format: .xml, options: .defaultValue)
  self = try Self.decoder.decode(Self.self, from: data)
 }
}

#if canImport(XMLCoder)
 import XMLCoder
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol XMLCodable: XMLEncodable & XMLDecodable & AutoCodable {}
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol XMLDecodable: AutoDecodable {}
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol XMLEncodable: AutoEncodable {}
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension XMLEncodable {
  static var encoder: XMLEncoder { XMLEncoder() }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension XMLDecodable {
  static var decoder: XMLDecoder { XMLDecoder() }
 }
#endif
#if canImport(CodableCSV)
 import CodableCSV
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol CSVCodable: CSVEncodable & CSVDecodable & AutoCodable {}
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol CSVDecodable: AutoDecodable {}
 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension CSVDecodable {
  static var decoder: CSVDecoder { CSVDecoder() }
 }

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public protocol CSVEncodable: AutoEncodable {}

 @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
 public extension CSVDecodable {
  static var encoder: CSVEncoder { CSVEncoder() }
 }
#endif
