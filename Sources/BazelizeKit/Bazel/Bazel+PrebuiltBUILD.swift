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
                    file.label?.hasPrefix("//Prebuilt:") == true
                }

            let frameworks = imported.filter { file in
                file.fileType == "wrapper.framework"
            }

            let xcframeworks = imported.filter { file in
                file.fileType == "wrapper.xcframework"
            }

            buildFrameworks(frameworks)
            buildXCFrameworks(xcframeworks)
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
