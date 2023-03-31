import Foundation
import Combine

// @dynamicMemberLookup
public protocol JSONCodable: JSONEncodable & JSONDecodable & AutoCodable {
 init()
}

public protocol JSONDecodable: AutoDecodable {}
public protocol JSONEncodable: AutoEncodable {}

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

public extension JSONEncodable {
 static var encoder: JSONEncoder { JSONEncoder() }
}

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

public protocol PlistCodable: PlistEncodable & PlistDecodable & AutoCodable {}
public protocol PlistDecodable: AutoDecodable {}
public protocol PlistEncodable: AutoEncodable {}

public extension PlistEncodable {
 static var encoder: PropertyListEncoder { PropertyListEncoder() }
}

public extension PlistDecodable {
 static var decoder: PropertyListDecoder { PropertyListDecoder() }
 init(_ dictionary: [String: Any]) throws {
  let data =
   try PropertyListSerialization
    .data(fromPropertyList: dictionary, format: .xml, options: .defaultValue)
  self = try Self.decoder.decode(Self.self, from: data)
 }
}
