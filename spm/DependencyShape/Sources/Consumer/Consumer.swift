/// `Core` is what the other package calls its module, and what this source
/// calls it too: the alias renames what is compiled — `OtherCore` — so that
/// name can clash with something else in the graph without this source caring.
import AltCore
import Core
import Helper
import Local
import VendorCore

public enum Consumer {
    public static let everything = [local, helper, vendorCore, core]

    /// Two packages ship a product called `VendorCore`; these are the modules
    /// behind each one.
    public static let sameNamedProducts = [vendorCore, altCore]

    /// A dependency's own resource, which only that package's bundle holds.
    public static var vendored: String? {
        vendoredResource
    }
}
