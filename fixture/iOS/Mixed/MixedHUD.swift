import Foundation
import SVProgressHUDShare

/// Exposed to Objective-C with a type of a binary framework in its signature,
/// which is what puts `@import SVProgressHUDShare;` in `Mixed-Swift.h`.
@objc(MixedHUD)
public final class MixedHUD: NSObject {
    @objc(nameOf:)
    public static func name(of style: SVProgressHUDStyle) -> String {
        switch style {
        case .light: "light"
        case .dark: "dark"
        case .custom: "custom"
        @unknown default: "unknown"
        }
    }
}
