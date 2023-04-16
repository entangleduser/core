import Foundation
public struct UUIDTransaction<B: Transactional>: Transactional {
 public init() {}
 public init(from source: UUID, to target: B) {
  self.source = source
  self.target = target
 }

 public var source: UUID = .defaultValue
 public var target: B?
}

extension UUIDTransaction: Codable where B: Codable {}

extension UUIDTransaction: CustomStringConvertible where B: CustomStringConvertible {
 public var description: String {
  """
  \(source.uuidString)\
  \(target == nil ? .empty : "/\(target!)")
  """
 }
}

extension UUIDTransaction: LosslessStringConvertible where B: LosslessStringConvertible {
 public init?(_ description: String) {
  let splits = description.split(separator: "/", omittingEmptySubsequences: true)

  let uuidString = String(splits[0])
  guard let source = UUID(uuidString: uuidString) else { return nil }
  self.source = source

  let targetString = String(splits[1 ..< splits.endIndex].joined(separator: "/"))
  guard let target = B(targetString) else { return nil }
  self.target = target
 }
}

extension UUIDTransaction: Equatable where B: Equatable {
 public static func == (lhs: Self, rhs: Self) -> Bool {
  lhs.source == rhs.source && lhs.target == rhs.target
 }
}

extension UUIDTransaction: Hashable where B: Hashable {
 public func hash(into hasher: inout Hasher) {
  hasher.combine(source)
  hasher.combine(target)
 }
}

#if os(macOS)
 @available(macOS 12.0, *)
 public extension UUID {
  /// github.com/ericdke/ed2d8bd3d127c25bcc6b
  static func getSystemUUID() -> UUID? {
   let dev = IOServiceMatching("IOPlatformExpertDevice")
   let platformExpert: io_service_t = IOServiceGetMatchingService(
    kIOMainPortDefault, dev
   )
   let serialNumberAsCFString =
    IORegistryEntryCreateCFProperty(
     platformExpert,
     kIOPlatformUUIDKey as CFString,
     kCFAllocatorDefault, 0
    ).takeUnretainedValue()
   IOObjectRelease(platformExpert)
   if let result = serialNumberAsCFString as? String {
    return UUID(uuidString: result)
   }
   return nil
  }

  static let system: Self? = getSystemUUID()
 }

#elseif os(iOS) || os(watchOS) || os(tvOS)
 import UIKit
 public extension UUID {
  static func getSystemUUID() -> UUID? { UIDevice.current.identifierForVendor }
  static let system: Self? = getSystemUUID()
 }
#else
 extension Process {
  @inline(__always)
  var shell: String { environment?["SHELL"] ?? "/bin/sh" }
  @inline(__always)
  convenience init(_ command: String, args: some Sequence<String> = []) {
   self.init()
   self.launchPath = shell
   self.arguments = ["-c", command.appending(arguments: args)]
  }
 }

 @inline(__always) func process(
  command: String,
  _ args: some Sequence<String> = []
 ) throws -> String {
  let process = Process(command, args: args)
  let output = Pipe()
  var outputData = Data()

  process.standardOutput = output

  try process.run()

  outputData = output.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()

  return String(data: outputData, encoding: .utf8).unsafelyUnwrapped
 }

 public extension UUID {
  static func getSystemUUID() -> UUID? {
   guard let uuidString =
    (try? process(command: "cat", ["/sys/class/dmi/id/product_uuid"]) ??
     try? process(command: "dmidecode", ["-s", "system-uuid"])).wrapped
   else { return nil }
   return UUID(uuidString: uuidString)
  }

  static let system: Self? = getSystemUUID()
 }
#endif

extension UUID: LosslessStringConvertible {
 public init?(_ description: String) { self.init(uuidString: description) }
}

public extension String {
 static var username: String { NSUserName() }
 static var fullUserName: String { NSFullUserName() }
}
