import struct Foundation.CharacterSet
public extension Character {
 var isAlphaNumeric: Bool {
  guard let scalar = unicodeScalars.first else { return false }
  return CharacterSet.alphanumerics.contains(scalar)
 }

 var isUnderscore: Bool {
  guard let scalar = unicodeScalars.first else { return false }
  return scalar == "_"
 }

 mutating func uppercase() {
  self = Character(self.uppercased())
 }
}

public extension Character {
 static var period: Character { "." }
 static var space: Character { " " }
 static var newline: Character { "\n" }
 static var `return`: Character { "\r" }
 static var tab: Character { "\t" }
 static var bullet: Character { "•" }
 static var arrow: Character { "→" }
 static var fullstop: Character { "⇥" }
 static var checkmark: Character { "✔︎" }
 static var xmark: Character { "✘" }
 static var invisibleReturn: Character { "⏎" }
}
