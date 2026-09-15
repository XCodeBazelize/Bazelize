import Foundation
import PathKit
import Util
import XCode2

extension Target {
    /// What the rule declares: the frameworks the project links plus the ones its
    /// Objective-C sources import.
    func sdkFrameworks(project: Project) -> [String]? {
        let all = Set(frameworksSDK).union(autolinkedFrameworks(project: project))
            .subtracting(weakFrameworksSDK)
        return all.isEmpty ? nil : all.sorted()
    }

    /// SDK frameworks the Objective-C half imports as modules.
    ///
    /// Xcode links them without anyone declaring them: clang records an autolink
    /// directive for every framework module it imports. Bazel compiles with
    /// `-fno-autolink` — it wants the dependency declared — so the imports are read
    /// out of the sources instead, exactly the set clang would have recorded.
    func autolinkedFrameworks(project: Project) -> [String] {
        let available = SDKFrameworks.names(for: platformSDK)
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

/// The frameworks an SDK ships, which is what makes an import autolinkable.
private enum SDKFrameworks {
    static func names(for platform: SDK?) -> Set<String> {
        let sdk = sdkName(for: platform)

        if let cached = cache[sdk] {
            return cached
        }

        let names = read(sdk: sdk)
        cache[sdk] = names
        return names
    }

    private nonisolated(unsafe) static var cache: [String: Set<String>] = [:]

    private static func sdkName(for platform: SDK?) -> String {
        switch platform {
        case .iOS: return "iphoneos"
        case .tvOS: return "appletvos"
        case .watchOS: return "watchos"
        default: return "macosx"
        }
    }

    private static func read(sdk: String) -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--sdk", sdk, "--show-sdk-path"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        guard (try? process.run()) != nil else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !output.isEmpty
        else {
            return []
        }

        let roots = [
            Path(output) + "System/Library/Frameworks",
            Path(output) + "System/iOSSupport/System/Library/Frameworks"
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
            #"#\s*(?:import|include)\s+<([A-Za-z_][A-Za-z0-9_]*)/"#
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
