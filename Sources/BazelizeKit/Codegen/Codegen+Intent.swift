import BazelRules
import Foundation
import PathKit
import Starlark

/// `.intentdefinition`
///
/// Xcode compiles intent definitions into the target's own module, so the
/// generated sources are fed straight into the target's library instead of
/// becoming a separate module the sources would have to import.
extension Target {
    // MARK: Internal

    var intentDefinitions: [String] {
        srcs.filter { $0.hasSuffix(".intentdefinition") }
    }

    var intentSources: [Starlark.Label] {
        intentDefinitions.map { definition in
            .named(":\(Self.intentTargetName(for: definition))")
        }
    }

    func generateIntentLibraries(_ builder: CodeBuilder, _: Kit) {
        guard !intentDefinitions.isEmpty else { return }

        builder.load(loadableRule: Rules.Apple.Resources.apple_intent_library)

        for definition in intentDefinitions {
            builder.call(
                Rules.Apple.Resources.Call.apple_intent_library(
                    name: Self.intentTargetName(for: definition),
                    src: .named(definition),
                    language: "Swift",
                    tags: ["manual"],
                    testonly: isTest,
                    visibility: .private))
        }
    }

    // MARK: Private

    private static func intentTargetName(for definition: String) -> String {
        "\(Path(definition).lastComponentWithoutExtension)_intent"
    }
}
