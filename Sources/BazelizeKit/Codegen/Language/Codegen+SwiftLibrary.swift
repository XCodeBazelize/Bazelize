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
                copts: bridgingHeaderCopts,
                module_name: codegenModuleName,
                srcs: .build {
                    srcs_swift
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
                swiftc_inputs: .build {
                    bridgingHeader
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
        return "Sources/\(header)"
    }

    var bridgingHeaderCopts: [String]? {
        guard let bridgingHeader else { return nil }
        return ["-import-objc-header", "$(location \(bridgingHeader))"]
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
    func applicationHost(project _: Project) -> String? {
        guard let host = prefer(\.testHost) else { return nil }
        guard let _ = prefer(\.bundleLoader) else { return nil }
        guard let targetName = host.components(separatedBy: "/").last else { return nil }
        return "//Targets/\(targetName):\(targetName)_library"
    }
}
