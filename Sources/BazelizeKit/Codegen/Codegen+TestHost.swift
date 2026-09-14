import Foundation
import PathKit
import Starlark
import XCode2

extension Target {
    /// The application a unit-test bundle is loaded into, from `TEST_HOST` or
    /// `BUNDLE_LOADER`.
    ///
    /// Xcode resolves the bundle's undefined symbols against the host executable
    /// with `-bundle_loader`, and its project-wide header map lets the test include
    /// the host's headers by name. A Bazel test bundle has neither, so the host's
    /// library is linked into it: that covers both.
    func testHostLibraries(project: Project?) -> [Starlark.Label] {
        guard isTest, let host = testHostTarget(project: project) else { return [] }

        let label = Starlark.Label.named("//Targets/\(host.name):\(host.name)_library")
        /// A test target usually also declares the host as a target dependency, and
        /// Bazel rejects a duplicated label in `deps`.
        return frameworksLibrary.contains(label) ? [] : [label]
    }

    // MARK: Private

    private func testHostTarget(project: Project?) -> Target? {
        guard let project, let name = hostBundleName else { return nil }
        return project.targets.first { $0.name == name }
    }

    /// `TEST_HOST` points at the executable inside the host bundle, e.g.
    /// `$(BUILT_PRODUCTS_DIR)/MacPass.app/Contents/MacOS/MacPass`.
    private var hostBundleName: String? {
        guard let setting = prefer(\.testHost) ?? prefer(\.bundleLoader) else { return nil }

        let components = Path(setting).components
        guard let bundle = components.first(where: { $0.hasSuffix(".app") }) else { return nil }
        return String(bundle.dropLast(".app".count))
    }
}
