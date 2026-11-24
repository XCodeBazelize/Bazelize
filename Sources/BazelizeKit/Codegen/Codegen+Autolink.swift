import Foundation
import PathKit
import Util
import Xcode

extension Target {
    /// What the rule declares: the frameworks the project links plus the ones its
    /// Objective-C sources import.
    func sdkFrameworks(project: Project, available: Set<String>) -> [String]? {
        let all = Set(frameworksSDK).union(autolinkedFrameworks(project: project, available: available))
            .subtracting(weakFrameworksSDK)
        return all.isEmpty ? nil : all.sorted()
    }

    /// SDK frameworks the Objective-C half imports as modules.
    ///
    /// Xcode links them without anyone declaring them: clang records an autolink
    /// directive for every framework module it imports. Bazel compiles with
    /// `-fno-autolink` — it wants the dependency declared — so the imports are read
    /// out of the sources instead, exactly the set clang would have recorded.
    func autolinkedFrameworks(project: Project, available: Set<String>) -> [String] {
        guard !available.isEmpty else { return [] }

        let workspace = Path(project.workspacePath)
        let sources = srcs_c + srcs_objc + srcs_cpp + srcs_objcpp
            + moduleHeaderFiles(project: project) + internalHeaderFiles(project: project)

        var result = Set<String>()

        for source in sources {
            let path = workspace + Path(source.delete(prefix: "Sources/") ?? source)
            guard let content: String = try? path.read() else { continue }

            for name in content.importedModuleNames where available.contains(name) {
                result.insert(name)
            }
        }

        return result.sorted()
    }
}

// MARK: - SDKFrameworks

/// The frameworks an SDK ships, which is what makes an import autolinkable.
actor SDKFrameworks {
    private static let shared = SDKFrameworks()
    private var cache: [String: Task<Set<String>, Never>] = [:]

    static func load(targets: [Target]) async -> [String: Set<String>] {
        var names: Set<String> = []
        for target in targets where !target.srcs_c.isEmpty || !target.srcs_objc.isEmpty
            || !target.srcs_cpp.isEmpty || !target.srcs_objcpp.isEmpty
        {
            names.insert(sdkName(for: target.platformSDK))
        }
        var result: [String: Set<String>] = [:]
        for sdk in names.sorted() {
            result[sdk] = await shared.names(for: sdk)
        }
        return result
    }

    private func names(for sdk: String) async -> Set<String> {
        if let task = cache[sdk] { return await task.value }
        // Cache the in-flight query before awaiting it; concurrent generations
        // share discovery without sharing mutable framework sets.
        let task = Task { await Self.read(sdk: sdk) }
        cache[sdk] = task
        return await task.value
    }

    static func sdkName(for platform: SDK?) -> String {
        switch platform {
        case .iOS: return "iphoneos"
        case .tvOS: return "appletvos"
        case .watchOS: return "watchos"
        default: return "macosx"
        }
    }

    private static func read(sdk: String) async -> Set<String> {
        guard let root = try? await Commands.showSDK(sdk: sdk) else { return [] }
        let roots = [
            root + "System/Library/Frameworks",
            root + "System/iOSSupport/System/Library/Frameworks",
        ]

        var names = Set<String>()
        for root in roots {
            guard let children = try? root.children() else { continue }
            for child in children where child.extension == "framework" {
                names.insert(child.lastComponentWithoutExtension)
            }
        }

        return names
    }
}

extension String {
    /// `@import Accelerate;`, `#import <Accelerate/Accelerate.h>` and the `#include`
    /// spelling of the same.
    fileprivate var importedModuleNames: [String] {
        let patterns = [
            #"@import\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            #"#\s*(?:import|include)\s+<([A-Za-z_][A-Za-z0-9_]*)/"#,
        ]

        return patterns.flatMap { pattern -> [String] in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

            return regex.matches(in: self, range: NSRange(startIndex..., in: self)).compactMap { match in
                guard let range = Range(match.range(at: 1), in: self) else { return nil }
                return String(self[range])
            }
        }
    }
}
