import BazelRules
import PathKit
import Starlark
import XCode2

extension Bazel {
    struct PrebuiltBuild: BazelFile {
        let path: Path
        public let builder = CodeBuilder()
        init(_ root: Path) {
            path = root + "Prebuilt" + "BUILD"
        }

        var code: String {
            builder.build()
        }

        mutating func setup(_ kit: Kit) {
            let imported = kit.project.targets
                .flatMap(\.files.frameworks)
                .filter { file in
                    guard file.label?.hasPrefix("//Prebuilt:") == true else { return false }
                    /// A binary that only exists after a bootstrap script has run is
                    /// not importable, and declaring it leaves the workspace
                    /// unloadable — iina references dylibs it builds separately.
                    guard let fullPath = file.fullPath else { return false }
                    return Path(fullPath).exists
                }

            let frameworks = imported.filter { file in
                file.fileType == "wrapper.framework"
            }

            let xcframeworks = imported.filter { file in
                file.fileType == "wrapper.xcframework"
            }

            let staticLibraries = imported.filter { file in
                file.fileType == "archive.ar"
            }

            let dynamicLibraries = imported.filter { file in
                file.fileType == "compiled.mach-o.dylib"
            }

            buildFrameworks(frameworks)
            buildXCFrameworks(xcframeworks)
            buildLibraries(staticLibraries, dynamicLibraries)
        }

        /// Checked-in `.a`/`.dylib` binaries; `cc_import` is the only rule that takes
        /// a bare library and still exposes it to Swift and Objective-C targets.
        private func buildLibraries(_ staticLibraries: [XCode.File], _ dynamicLibraries: [XCode.File]) {
            guard !staticLibraries.isEmpty || !dynamicLibraries.isEmpty else { return }
            builder.load(.cc_import)

            for file in unique(staticLibraries) {
                guard let path = file.path, !path.isEmpty else { continue }
                builder.call(
                    Rules.Cc.Call.cc_import(
                        name: Path(path).lastComponentWithoutExtension,
                        static_library: .named(Path(path).lastComponent),
                        visibility: .public))
            }

            for file in unique(dynamicLibraries) {
                guard let path = file.path, !path.isEmpty else { continue }
                builder.call(
                    Rules.Cc.Call.cc_import(
                        name: Path(path).lastComponentWithoutExtension,
                        shared_library: .named(Path(path).lastComponent),
                        visibility: .public))
            }
        }

        private func buildXCFrameworks(_ files: [XCode.File]) {
            guard !files.isEmpty else { return }
            builder.load(.apple_dynamic_xcframework_import)

            for file in unique(files) {
                guard let path = file.path, !path.isEmpty else { continue }
                let name = Path(path).lastComponentWithoutExtension
                builder.call(
                    Rules.Apple.General.Call.apple_dynamic_xcframework_import(
                        name: name,
                        xcframework_imports: Starlark.glob([
                            "\(Path(path).lastComponent)/**",
                        ]),
                        visibility: .public))
            }
        }

        private func buildFrameworks(_ files: [XCode.File]) {
            guard !files.isEmpty else { return }
            builder.load(.apple_dynamic_framework_import)

            for file in unique(files) {
                guard let path = file.path, !path.isEmpty else { continue }
                let name = Path(path).lastComponentWithoutExtension
                builder.call(
                    Rules.Apple.General.Call.apple_dynamic_framework_import(
                        name: name,
                        framework_imports: Starlark.glob([
                            "\(Path(path).lastComponent)/**",
                        ]),
                        visibility: .public))
            }
        }

        private func unique(_ files: [XCode.File]) -> [XCode.File] {
            var seen = Set<String>()
            return files.filter { file in
                guard let path = file.path, !path.isEmpty else { return false }
                return seen.insert(path).inserted
            }
        }
    }
}
