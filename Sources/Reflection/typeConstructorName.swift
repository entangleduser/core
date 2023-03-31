/** Returns name of a given unapplied generic type. `Button<Text>` and
 `Button<Image>` types are different, but when reconciling the tree of mounted views
 they are treated the same, thus the `Button` part of the type (the type constructor)
 is returned.
 */
public func typeConstructorName(_ type: Any.Type) -> String {
 String(String(reflecting: type).prefix { $0 != "<" })
}
