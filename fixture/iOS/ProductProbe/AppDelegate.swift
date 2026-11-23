import Foundation
import ProductProbeFramework
import UIKit

// MARK: - AppDelegate

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil)
        -> Bool
    {
        do {
            let bundle = Bundle.main
            guard
                let resource = bundle.url(forResource: "Probe", withExtension: "txt"),
                let plugins = bundle.builtInPlugInsURL,
                let plugin = Bundle(url: plugins.appendingPathComponent("ProductProbeExtension.appex")),
                let identifier = plugin.bundleIdentifier,
                let extensionInfo = plugin.infoDictionary?["NSExtension"] as? [String: Any],
                let point = extensionInfo["NSExtensionPointIdentifier"] as? String,
                let icons = bundle.infoDictionary?["CFBundleIcons"] as? [String: Any],
                let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                let icon = primary["CFBundleIconName"] as? String,
                let alternateIcons = icons["CFBundleAlternateIcons"] as? [String: Any],
                let alternate = alternateIcons["AlternateIcon"] as? [String: Any],
                let alternateIcon = alternate["CFBundleIconName"] as? String
            else { fatalError("Product probe is missing its resource, extension, or icon declarations") }
            let proof = [
                "resource": try String(contentsOf: resource, encoding: .utf8),
                "extensionID": identifier,
                "extensionPoint": point,
                "framework": ProductProbeFramework.test(),
                "icon": icon,
                "alternateIcon": alternateIcon,
            ]
            let documents = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            try JSONSerialization.data(withJSONObject: proof, options: [.sortedKeys])
                .write(to: documents.appendingPathComponent("ProductProbe.json"), options: .atomic)
        } catch {
            fatalError("Product probe failed: \(error)")
        }
        return true
    }

    func application(
        _: UIApplication,
        configurationForConnecting session: UISceneSession,
        options _: UIScene.ConnectionOptions)
        -> UISceneConfiguration
    {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

// MARK: - SceneDelegate

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let controller = UIViewController()
        let label = UILabel()
        label.text = "Product probe ready"
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        controller.view = label
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
    }
}
