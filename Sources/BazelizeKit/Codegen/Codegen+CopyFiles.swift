import BazelRules
import Foundation
import PathKit
import Starlark
import XCode2

extension Target {
    /// Products Xcode copies into the bundle outside the framework and extension
    /// phases: a login-item helper app, a privileged helper tool, an XPC service.
    ///
    /// rules_apple takes them as `additional_contents`, keyed by the subdirectory of
    /// `Contents` they belong in, and knows how to place an app bundle, a bare
    /// executable or a plain file.
    func additionalContents(project: Project?) -> [String: String] {
        copiedProducts(project: project).reduce(into: [:]) { result, copied in
            result[copied.label] = copied.subdirectory
        }
    }

    /// A tool's binary is named after its rule, so one whose `PRODUCT_NAME` differs
    /// is copied to that name first — the app looks it up by name, and a launch
    /// daemon's plist points at it.
    func generateCopiedProducts(_ builder: CodeBuilder, _ kit: Kit) {
        for copied in copiedProducts(project: kit.project) where copied.rename != nil {
            guard let rename = copied.rename else { continue }

            builder.call(
                Rules.Builtin.Call.genrule(
                    name: rename.rule,
                    srcs: .build {
                        [rename.product]
                    },
                    outs: [rename.name],
                    cmd: "cp $(location \(rename.product)) $@",
                    visibility: .private))
        }
    }

    // MARK: Private

    private struct CopiedProduct {
        let label: String
        let subdirectory: String
        let rename: (rule: String, product: String, name: String)?
    }

    private func copiedProducts(project: Project?) -> [CopiedProduct] {
        guard let project else { return [] }

        /// A build phase entry does not say where it comes from, so the copied files
        /// answer that: only a product of another target is a rule dependency, a file
        /// out of the source tree is just a file.
        let products = Set(files.copyFiles.filter { file in
            file.sourceTree == "BUILT_PRODUCTS_DIR"
        }.compactMap { file in
            file.name ?? file.path
        })

        var result: [CopiedProduct] = []
        var seen = Set<String>()

        for phase in buildPhases where phase.type == "CopyFiles" {
            guard let subdirectory = phase.contentsSubdirectory else { continue }

            for file in phase.files {
                guard
                    let component = file.name ?? file.path,
                    products.contains(component),
                    let sibling = project.product(named: component),
                    seen.insert(component).inserted
                else {
                    continue
                }

                let product = "//Targets/\(sibling.name):\(sibling.name)"
                guard
                    component != sibling.name,
                    sibling.productType == "com.apple.product-type.tool"
                else {
                    result.append(.init(label: product, subdirectory: subdirectory, rename: nil))
                    continue
                }

                let rule = "\(sibling.name)_product"
                result.append(
                    .init(
                        label: ":\(rule)",
                        subdirectory: subdirectory,
                        rename: (rule: rule, product: product, name: component)))
            }
        }

        return result
    }
}

extension Project {
    /// The target whose product is copied under this file name.
    ///
    /// A copy phase names the product, which `PRODUCT_NAME` can rename: the Stats
    /// `SMC` target builds `smc`, and its `Helper` builds a tool named after the
    /// bundle identifier.
    fileprivate func product(named component: String) -> Target? {
        let base = Path(component).lastComponentWithoutExtension

        return targets.first { target in
            let names = [target.name, target.productName, target.prefer(\.metadata.productName)]
                .compactMap { $0 }
            return names.contains(component) || names.contains(base)
        }
    }
}

extension XCode2.XCode.BuildPhase {
    /// Where a copy phase lands, relative to `Contents`.
    ///
    /// `nil` for a destination another rule attribute owns — a framework or an
    /// extension — and for one no bundle subdirectory can express.
    fileprivate var contentsSubdirectory: String? {
        guard let destination else { return nil }

        let path = (destination.path ?? "")
            .replacingOccurrences(of: "$(CONTENTS_FOLDER_PATH)", with: "")
            .replacingOccurrences(of: "${CONTENTS_FOLDER_PATH}", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        /// `PBXCopyFilesBuildPhase.SubFolder`, as Xcode writes it.
        switch destination.subfolderSpec {
        case 1, 16:
            /// Relative to the wrapper, so the `Contents` prefix is already there.
            let trimmed = path.delete(prefix: "Contents/") ?? path
            return trimmed.isEmpty ? nil : trimmed
        case 6:
            return join("MacOS", path)
        case 7:
            return join("Resources", path)
        case 12:
            return join("SharedSupport", path)
        default:
            /// 10 is `frameworks`, 13 is `extensions`, 0 is an absolute path.
            return nil
        }
    }

    private func join(_ base: String, _ path: String) -> String {
        path.isEmpty ? base : "\(base)/\(path)"
    }
}
