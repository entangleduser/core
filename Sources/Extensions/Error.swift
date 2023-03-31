
import protocol Foundation.LocalizedError
public extension Error {
 var message: String {
  (self as? LocalizedError)?.errorDescription ??
   (self as? LocalizedError)?.failureReason ??
   localizedDescription
 }

 var debugMessage: [String] {
  [String(describing: self), _code.description, message]
 }
}
