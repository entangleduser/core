public extension StringProtocol {
 var trimmed: String {
  replacingOccurrences(
   of: "\\s+$",
   with: "",
   options: .regularExpression
  )
 }

 var withoutSpaces: String {
  replacingOccurrences(of: " ", with: "")
 }

 static var period: Self { "." }
 static var hyphen: Self { "-" }
 static var space: Self { " " }
 static var newline: Self { "\n" }
 static var bullet: Self { "•" }
 static var arrow: Self { "→" }
 static var fullstop: Self { "⇥" }
 static var checkmark: Self { "✔︎" }
 static var xmark: Self { "✘" }
 static var `return`: Self { "⏎" }
}

public extension String {
 mutating func capitalize() { self = capitalized }
}

public extension Substring {
 mutating func capitalize() { self = Substring(capitalized) }
}

// MARK: Operations
public extension [String] {
 func rename(
  _ base: Element,
  prefix: Element? = .none,
  includePrefixes: Bool = false,
  extension: Element? = .none,
  caseSensitive: Bool = false,
  offset: Int = 1
 ) -> Element {
  guard notEmpty else { return base }
  let adjustedOffset = 0 + offset
  var count: Int = adjustedOffset
  var elements =
   (caseSensitive ? sorted() : sorted().map { $0.lowercased() })
  for string in elements {
   let components =
    (caseSensitive ? string : string.lowercased())
    .components(separatedBy: caseSensitive ? base : base.lowercased())
   guard components.count == 2,
         components[0].isEmpty,
         var last = components.last
   else {
    elements.remove(at: 0)
    continue
   }
   if let `extension` {
    let `extension` = "\(caseSensitive ? `extension` : `extension`.lowercased())"
    last = last.replacingOccurrences(of: ".\(`extension`)", with: "")
   }
   let split = last.split(whereSeparator: \.isWhitespace)
   guard split.notEmpty else {
    count += 1
    continue
   }
   let first = String(split.first!)
   if let prefix,
      (caseSensitive ? first : first.lowercased())
      == (caseSensitive ? prefix : prefix.lowercased()) {
    if let last = split.last,
       let index = Int(last),
       index == count + 1 {
     count = index
     continue
    } else if split.count == 1 {
     count += 1
     continue
    }
   } else if split.count == 1 || includePrefixes,
             let last = split.last,
             let index = Int(last) {
    count = index == count + 1 ? index : count + 1
    continue
   }
   guard split.count == 1 || (split.count > 1 && includePrefixes) else {
    continue
   }
   count += 1
  }
  guard elements.notEmpty else { return base }
  //  guard elements.count > 1 else {
  //   return "\(base) \(prefix?.wrapped == nil ? adjustedOffset.description : prefix!)"
  //  }
  return """
  \(base) \
  \(prefix?.wrapped == nil ? .empty : "\(prefix!)\(count > 1 ? " " : .empty)")\
  \(count.description)
  """
 }
}
