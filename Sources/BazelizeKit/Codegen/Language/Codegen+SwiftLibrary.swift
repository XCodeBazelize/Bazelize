import PathKit

extension Target {
    // MARK: Internal

    func generateSwiftLibrary(
        _ builder: CodeBuilder,
        _ kit: Kit,
        extraDeps: [Starlark.Label] = [])
    {
        let project = kit.project
        let plugin = kit.plugins.compactMap {
            $0[name]
        }.flatMap(\.deps)

        let builtins: [String] = kit.builtinPlugins
            .compactMap(\.target)
            .reduce([]) { origin, next in
                let data = next[name] ?? []
                return origin + data
            }

        builder.load(.swift_library)
        builder.call(
            Rules.Swift.Call.swift_library(
                name: "\(name)_swift",
                copts: swiftCopts(project: project),
                module_name: codegenModuleName,
                srcs: .build {
                    srcs_swift
                    intentSources
                    assetSymbolSources
                },
                deps: .build {
                    extraDeps
                    linkedFrameworksLibrary(project: project)
                    applicationHost(project: project)
                    plugin
                    builtins
                },
                data: .build {
                    if !assets.isEmpty {
                        ":Assets"
                    }
                    xibs
                    storyboards
                },
                defines: defines(project: project),
                linkopts: sdkLinkopts,
                swiftc_inputs: .build {
                    bridgingHeader
                    definesHeader
                },
                testonly: isTest,
                visibility: .private))

        builder.call(
            Rules.Builtin.Call.alias(
                name: "\(name)_library",
                actual: .named("\(name)_swift"),
                visibility: .public))
    }


    /// `SWIFT_OBJC_BRIDGING_HEADER`, relative to the target's `Sources/` tree.
    ///
    /// rules_swift has no bridging-header attribute, so the header is passed
    /// straight to the compiler and declared as a `swiftc_inputs` file.
    var bridgingHeader: String? {
        guard let header = prefer(\.bridgingHeader), !header.isEmpty, !header.hasPrefix("/") else { return nil }
        /// Build settings carry paths like `./Target/Bridge.h`, which Bazel rejects
        /// as a label.
        return "Sources/\(Path(header).normalize().string)"
    }

    var bridgingHeaderCopts: [String]? {
        guard let bridgingHeader else { return nil }
        return ["-import-objc-header", "$(location \(bridgingHeader))"]
    }

    /// Swift compiles a file named `main.swift` as top-level code and emits a `main`
    /// symbol. Xcode only does that for executables, so anything else — a framework
    /// with a `main.swift` is common — has to be parsed as a library.
    var parseAsLibraryCopts: [String] {
        switch productType {
        case "com.apple.product-type.application",
             "com.apple.product-type.tool":
            return []
        default:
            break
        }

        guard srcs_swift.contains(where: { $0.hasSuffix("/main.swift") || $0 == "main.swift" }) else {
            return []
        }

        return ["-parse-as-library"]
    }

    func swiftCopts(project: Project) -> [String]? {
        var copts = (bridgingHeaderCopts ?? []) + parseAsLibraryCopts
        if bridgingHeader != nil {
            copts += swiftIncludeCopts(project: project) + clangDefineCopts()
        }
        return copts.isEmpty ? nil : copts
    }

    /// Same flags minus the bridging header: a mixed-language target exposes those
    /// declarations through its own clang module instead. The module's headers can
    /// still reach for the target's include paths, so `swiftc` needs them too.
    func moduleSwiftCopts(project: Project) -> [String]? {
        let copts = parseAsLibraryCopts + swiftIncludeCopts(project: project) + clangDefineCopts()
        return copts.isEmpty ? nil : copts
    }

    /// `swift_library` has no `sdk_frameworks`, so system frameworks and dylibs from
    /// the target's Frameworks phase are linked through raw linker flags.
    var sdkLinkopts: [String]? {
        let searchPaths = frameworkSearchPathsSDK.map { "-F\($0)" }
        let frameworks = frameworksSDK.flatMap { ["-framework", $0] }
        let weakFrameworks = weakFrameworksSDK.flatMap { ["-weak_framework", $0] }
        let dylibs = dylibsSDK.map { name in
            "-l\(name.delete(prefix: "lib") ?? name)"
        }

        // Bazel expands `$` in `linkopts` as a Make variable; a weak-symbol flag like
        // `-Wl,-U,_OBJC_CLASS_$_X` has to escape it.
        let extra = (prefer(\.otherLinkerFlags) ?? []).map { flag in
            flag.replacingOccurrences(of: "$", with: "$$")
        }
        let flags = searchPaths + frameworks + weakFrameworks + dylibs + extra
        return flags.isEmpty ? nil : flags
    }

    // MARK: Private

    func defines(project: Project) -> Starlark.Value {
        select(\.swiftDefine, project: project).map { text -> [String] in
            let flags: [String] = (text ?? "").split(separator: " ").map(String.init)

            var isPreviousDefine = false
            var result: [String] = []
            for flag in flags {
                if flag == "-D" {
                    isPreviousDefine = true
                } else if isPreviousDefine {
                    /// -D ABC
                    result.append(flag)
                    isPreviousDefine = false
                } else if flag.hasPrefix("-D") {
                    /// -DABC
                    result.append(flag.delete(prefix: "-D"))
                }
            }

            return result
        }.starlark
    }

    /// Unittest's dependency from application
    ///
    /// BUNDLE_LOADER
    ///     $(TEST_HOST)
    /// TEST_HOST
    ///     $(BUILT_PRODUCTS_DIR)/Example.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Example
    ///     build/Debug-iphoneos/Example.app//Example
    func applicationHost(project: Project) -> String? {
        guard let host = prefer(\.testHost) else { return nil }
        guard let _ = prefer(\.bundleLoader) else { return nil }
        guard let targetName = host.components(separatedBy: "/").last else { return nil }

        let label = "//Targets/\(targetName):\(targetName)_library"
        /// A test target usually also declares the host as a target dependency, and
        /// Bazel rejects a duplicated label in `deps`.
        guard !linkedFrameworksLibrary(project: project).contains(where: { $0.value == label }) else { return nil }

        return label
    }
}
