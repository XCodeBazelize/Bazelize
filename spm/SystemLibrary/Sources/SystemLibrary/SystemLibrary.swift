import CGreet
import CSecurity
import CZlib
import Foundation

public enum SystemLibrary {
    /// From the module that links a library.
    public static var version: String {
        String(cString: zlibVersion())
    }

    /// From the module that links a framework: `Security` is linked because
    /// its module map says so, and nothing else here pulls it in.
    public static var securityMessage: String? {
        SecCopyErrorMessageString(errSecSuccess, nil).map { $0 as String }
    }

    /// From the module whose header `pkg-config` alone knows the way to.
    public static var greeting: Int32 {
        greet_value()
    }
}
