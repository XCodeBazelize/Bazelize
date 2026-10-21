import Foundation

// MARK: - Starlark.Format

extension Starlark {
    /// The order buildifier puts things in.
    ///
    /// A generated workspace lints itself with `bazel run //:lint`, which is
    /// buildifier in check mode. Anything written in an order buildifier would
    /// change is a reformat report on every run, for a file nobody edits. So
    /// the order below is buildifier's own, taken from its tables: an argument
    /// list, a label list and a `load` sort here the way they would sort there.
    public enum Format {
        /// `tables.NamePriority`. Everything absent sorts at 0, between the
        /// negative names that lead a rule and the positive ones that trail it.
        private static let namePriority: [String: Int] = [
            "name": -99,
            "archive_override.module_name": -99,
            "git_override.module_name": -99,
            "local_path_override.module_name": -99,
            "multiple_version_override.module_name": -99,
            "single_version_override.module_name": -99,
            "bazel_dep.version": -98,
            "module.version": -98,
            "gwt_name": -98,
            "package_name": -97,
            "visible_node_name": -96,
            "size": -95,
            "timeout": -94,
            "testonly": -93,
            "src": -92,
            "srcdir": -91,
            "srcs": -90,
            "out": -89,
            "outs": -88,
            "hdrs": -87,
            "has_services": -86,
            "include": -85,
            "of": -84,
            "baseline": -83,
            "destdir": 1,
            "exports": 2,
            "runtime_deps": 3,
            "deps": 4,
            "implementation": 5,
            "implements": 6,
            "alwayslink": 7,
        ]

        /// `tables.IsSortableListArg`: the attributes whose list of strings has
        /// no meaning in its order.
        private static let sortableArguments: Set = [
            "cc_deps",
            "common_deps",
            "compile_deps",
            "configs",
            "constraints",
            "data",
            "default_visibility",
            "deps",
            "deps_java",
            "exported_deps",
            "exports",
            "filegroups",
            "files",
            "hdrs",
            "implementation_deps",
            "imports",
            "includes",
            "inherits",
            "javadeps",
            "lib_deps",
            "module_deps",
            "outs",
            "packages",
            "plugin_modules",
            "private_deps",
            "proto_deps",
            "protos",
            "pubs",
            "resources",
            "runtime_deps",
            "shared_deps",
            "similar_deps",
            "srcs",
            "swigdeps",
            "swig_includes",
            "tags",
            "test_data",
            "test_deps",
            "test_srcs",
            "test_tags",
            "tests",
            "tools",
            "to_start_extensions",
            "visibility",
        ]

        /// `tables.SortableDenylist`: an attribute whose order is the build's
        /// business even though its name says otherwise.
        private static let unsortableArguments: Set = [
            "genrule.outs",
            "genrule.srcs",
            "cc_embed_data.srcs",
        ]

        /// `tables.IsLabelArg`: the attributes whose strings are labels, which
        /// is what makes `//a/b:b` and `//a/b` the same thing written twice.
        private static let labelArguments: Set = [
            "app_target",
            "appdir",
            "base_package",
            "build_deps",
            "cc_deps",
            "ccdeps",
            "common_deps",
            "compile_deps",
            "compiler",
            "data",
            "default_visibility",
            "dep",
            "deps",
            "deps_java",
            "dont_depend_on",
            "env_deps",
            "envscripts",
            "exported_deps",
            "exports",
            "externs_list",
            "files",
            "globals",
            "implementation",
            "implementation_deps",
            "implements",
            "includes",
            "interface",
            "jar",
            "jars",
            "javadeps",
            "lib_deps",
            "library",
            "malloc",
            "model",
            "mods",
            "module_deps",
            "module_target",
            "of",
            "plugins",
            "private_deps",
            "proto_deps",
            "proto_target",
            "protos",
            "resource",
            "resources",
            "runtime_deps",
            "scope",
            "shared_deps",
            "similar_deps",
            "source_jar",
            "src",
            "srcs",
            "stripped_targets",
            "suites",
            "swigdeps",
            "target",
            "target_devices",
            "target_platforms",
            "template",
            "test",
            "test_data",
            "test_deps",
            "test_srcs",
            "tests",
            "tests_deps",
            "tool",
            "tools",
            "visibility",
        ]

        /// `tables.LabelDenylist`: a label-shaped attribute that is read by
        /// other rules than the ones labels are read by.
        private static let unshortenableArguments: Set = [
            "package_group.includes",
        ]

        /// Whether this argument is given labels.
        public static func isLabel(rule: String, argument: String) -> Bool {
            guard !unshortenableArguments.contains("\(rule).\(argument)") else { return false }
            return labelArguments.contains(argument)
        }

        /// A label without the target qualifier it repeats: `//a/b:b` is
        /// `//a/b`, `@foo//:foo` is `@foo`. Anything else is itself.
        public static func shortened(label: String) -> String {
            var rest = Substring(label)
            var repository = ""
            if rest.hasPrefix("@") {
                guard let separator = rest.range(of: "//") else { return label }
                repository = String(rest[rest.index(after: rest.startIndex) ..< separator.lowerBound])
                guard !repository.isEmpty, repository.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" })
                else { return label }
                rest = rest[separator.lowerBound...]
            }
            guard rest.hasPrefix("//") else { return label }

            let parts = rest.dropFirst(2).split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return label }
            let package = String(parts[0])
            let target = String(parts[1])
            guard !target.contains(":") else { return label }

            if !package.isEmpty, package.split(separator: "/").last.map(String.init) == target {
                return repository.isEmpty ? "//\(package)" : "@\(repository)//\(package)"
            }
            if package.isEmpty, !repository.isEmpty, repository == target {
                return "@\(repository)"
            }
            return label
        }

        /// Where an argument sorts within the call it belongs to.
        public static func priority(rule: String, argument: String) -> Int {
            namePriority["\(rule).\(argument)"] ?? namePriority[argument] ?? 0
        }

        /// Whether the strings given to this argument may be reordered.
        public static func sorts(rule: String, argument: String) -> Bool {
            guard !unsortableArguments.contains("\(rule).\(argument)") else { return false }
            return sortableArguments.contains(argument)
        }

        /// buildifier's label order: plain strings, then `:`, then `//`, then
        /// `@`; within a group, the parts between `.` and `:` decide.
        public static func precedes(_ lhs: String, _ rhs: String) -> Bool {
            let left = sortKey(lhs)
            let right = sortKey(rhs)
            guard left.phase == right.phase else { return left.phase < right.phase }

            for (leftPart, rightPart) in zip(left.parts, right.parts) where leftPart != rightPart {
                return leftPart < rightPart
            }
            guard left.parts.count == right.parts.count else {
                return left.parts.count < right.parts.count
            }
            return lhs < rhs
        }

        /// buildifier's `load` order: a label with a repository goes first, a
        /// relative one last, and packages compare case-insensitively.
        public static func loadPrecedes(_ lhs: String, _ rhs: String) -> Bool {
            let leftIsExplicit = lhs.hasPrefix("@")
            let rightIsExplicit = rhs.hasPrefix("@")
            guard leftIsExplicit == rightIsExplicit else { return leftIsExplicit }

            let left = LoadLabel(lhs)
            let right = LoadLabel(rhs)
            guard left.repository == right.repository else { return left.repository < right.repository }
            guard left.package.isEmpty == right.package.isEmpty else { return left.package.isEmpty }
            guard left.package == right.package else { return precedes(path: left.package, right.package) }
            return precedes(path: left.target, right.target)
        }

        /// `comparePaths`: slash-separated, case-insensitive, case-sensitive
        /// only to break what is otherwise a tie.
        private static func precedes(path lhs: String, _ rhs: String) -> Bool {
            guard lhs != rhs else { return false }

            let left = lhs.split(separator: "/", omittingEmptySubsequences: false)
            let right = rhs.split(separator: "/", omittingEmptySubsequences: false)
            for (index, leftChunk) in left.enumerated() {
                guard index < right.count else { return false }
                let leftLower = leftChunk.lowercased()
                let rightLower = right[index].lowercased()
                if leftLower != rightLower { return leftLower < rightLower }
            }
            return lhs <= rhs
        }

        private static func sortKey(_ value: String) -> (phase: Int, parts: [String]) {
            let phase: Int
            switch true {
            case value.hasPrefix(":"):
                phase = 1
            case value.hasPrefix("//"):
                phase = 2
            case value.hasPrefix("@"):
                phase = 3
            default:
                phase = 0
            }
            let parts = value
                .replacingOccurrences(of: ":", with: ".")
                .components(separatedBy: ".")
            return (phase, parts)
        }
    }
}

// MARK: - LoadLabel

/// A `load` module split the way buildifier's label parser splits it.
/// A relative label gets a package that sorts after every real one, so
/// it lands last without a case of its own.
private struct LoadLabel {
    let repository: String
    let package: String
    let target: String

    init(_ value: String) {
        var rest = Substring(value)
        var repository = ""
        if rest.hasPrefix("@") {
            let separator = rest.range(of: "//")
            repository = String(rest[rest.startIndex ..< (separator?.lowerBound ?? rest.endIndex)])
            rest = separator.map { rest[$0.lowerBound...] } ?? ""
        }

        let isRelative = !rest.hasPrefix("//")
        if rest.hasPrefix("//") { rest = rest.dropFirst(2) }

        let parts = rest.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        self.repository = repository
        package = isRelative ? "\u{7F}" : String(parts.first ?? "")
        target = parts.count > 1 ? String(parts[1]) : ""
    }
}
