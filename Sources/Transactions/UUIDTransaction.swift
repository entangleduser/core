import Foundation
public struct UUIDTransaction<Target: Transactional>: Transactional {
 public init() {}
 public init(from source: UUID, to target: Target) {
  self.source = source
  self.target = target
 }

 public var source: UUID = .defaultValue
 public var target: Target?
}

extension UUIDTransaction: Codable where Target: Codable {}

extension UUIDTransaction: CustomStringConvertible where Target: CustomStringConvertible {
 public var description: String {
  """
  \(source.uuidString)\
  \(target == nil ? .empty : "/\(target!)")
  """
 }
}

extension UUIDTransaction: LosslessStringConvertible where Target: LosslessStringConvertible {
 public init?(_ description: String) {
  let splits = description.split(separator: "/", omittingEmptySubsequences: true)

  let uuidString = String(splits[0])
  guard let source = UUID(uuidString: uuidString) else { return nil }
  self.source = source

  let targetString = String(splits[1 ..< splits.endIndex].joined(separator: "/"))
  guard let target = Target(targetString) else { return nil }
  self.target = target
 }
}

public extension UUID {
 /// github.com/ericdke/ed2d8bd3d127c25bcc6b
 static func getSystemUUID() -> UUID? {
  let dev = IOServiceMatching("IOPlatformExpertDevice")
  let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, dev)
  let serialNumberAsCFString =
   IORegistryEntryCreateCFProperty(
    platformExpert,
    kIOPlatformUUIDKey as CFString,
    kCFAllocatorDefault, 0
   ).takeUnretainedValue()
  IOObjectRelease(platformExpert)
  if let result = serialNumberAsCFString as? String { return UUID(uuidString: result) }
  return nil
 }

 static let system: Self? = getSystemUUID()
}

extension UUID: LosslessStringConvertible {
 public init?(_ description: String) { self.init(uuidString: description) }
}
