//
//  Rules+Attributes.swift
//
//  Every attribute a rule wrapper gives a value to, declared once.
//

import Starlark

// MARK: - Attr

/// An attribute as Bazel spells it and the value it takes. A wrapper writes
/// `Attr.deps(deps)` rather than the string `"deps"`, so a misspelt attribute
/// does not compile; a nil value is an attribute left out of the call.
///
/// A namespace of its own rather than members of `Starlark.Statement.Argument`:
/// a result builder line that starts with `.` continues the line before it.
enum Attr {
    static func actual(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "actual" => $0 }
    }

    static func additional_contents(_ value: [String: String]?) -> Starlark.Statement.Argument? {
        value.map { "additional_contents" => $0 }
    }

    static func additional_objc_compiler_inputs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "additional_objc_compiler_inputs" => $0 }
    }

    static func aliases(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "aliases" => $0 }
    }

    static func always_include_developer_search_paths(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "always_include_developer_search_paths" => $0 }
    }

    static func alwayslink(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "alwayslink" => $0 }
    }

    static func app_clips(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "app_clips" => $0 }
    }

    static func app_icons(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "app_icons" => $0 }
    }

    static func archives(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "archives" => $0 }
    }

    static func args(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "args" => $0 }
    }

    static func aspect_hints(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "aspect_hints" => $0 }
    }

    static func avoid_deps(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "avoid_deps" => $0 }
    }

    static func binary(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "binary" => $0 }
    }

    static func build_setting_default(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "build_setting_default" => $0 }
    }

    static func build_setting_default(_ value: Int?) -> Starlark.Statement.Argument? {
        value.map { "build_setting_default" => $0 }
    }

    static func build_setting_default(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "build_setting_default" => $0 }
    }

    static func build_setting_default(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "build_setting_default" => $0 }
    }

    static func build_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "build_version" => $0 }
    }

    static func bundle(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "bundle" => $0 }
    }

    static func bundle_extension(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "bundle_extension" => $0 }
    }

    static func bundle_id(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "bundle_id" => $0 }
    }

    static func bundle_imports(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "bundle_imports" => $0 }
    }

    static func bundle_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "bundle_name" => $0 }
    }

    static func catalogs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "catalogs" => $0 }
    }

    static func clang_copts(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "clang_copts" => $0 }
    }

    static func clang_defines(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "clang_defines" => $0 }
    }

    static func clang_deps(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "clang_deps" => $0 }
    }

    static func clang_srcs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "clang_srcs" => $0 }
    }

    static func class_prefix(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "class_prefix" => $0 }
    }

    static func class_visibility(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "class_visibility" => $0 }
    }

    static func cmd(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "cmd" => $0 }
    }

    static func constraint_setting(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "constraint_setting" => $0 }
    }

    static func copts(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "copts" => $0 }
    }

    static func data(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "data" => $0 }
    }

    static func data(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "data" => $0 }
    }

    static func `default`(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "default" => $0 }
    }

    static func default_ios_sdk_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "default_ios_sdk_version" => $0 }
    }

    static func default_macos_sdk_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "default_macos_sdk_version" => $0 }
    }

    static func default_tvos_sdk_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "default_tvos_sdk_version" => $0 }
    }

    static func default_watchos_sdk_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "default_watchos_sdk_version" => $0 }
    }

    static func defines(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "defines" => $0 }
    }

    static func defines(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "defines" => $0 }
    }

    static func deps(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "deps" => $0 }
    }

    static func deps(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "deps" => $0 }
    }

    static func destination_platform(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "destination_platform" => $0 }
    }

    static func developer_platform(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "developer_platform" => $0 }
    }

    static func device_type(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "device_type" => $0 }
    }

    static func enable_modules(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "enable_modules" => $0 }
    }

    static func entitlements(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "entitlements" => $0 }
    }

    static func entry_classes(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "entry_classes" => $0 }
    }

    static func env(_ value: [String: String]?) -> Starlark.Statement.Argument? {
        value.map { "env" => $0 }
    }

    static func exclude_hdrs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "exclude_hdrs" => $0 }
    }

    static func exports(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "exports" => $0 }
    }

    static func `extension`(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "extension" => $0 }
    }

    static func `extension`(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "extension" => $0 }
    }

    static func extensions(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "extensions" => $0 }
    }

    static func fallback_profiles(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "fallback_profiles" => $0 }
    }

    static func families(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "families" => $0 }
    }

    static func features(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "features" => $0 }
    }

    static func flag_values(_ value: [String: String]?) -> Starlark.Statement.Argument? {
        value.map { "flag_values" => $0 }
    }

    static func framework_imports(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "framework_imports" => $0 }
    }

    static func frameworks(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "frameworks" => $0 }
    }

    static func generated_header_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "generated_header_name" => $0 }
    }

    static func generates_header(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "generates_header" => $0 }
    }

    static func hdrs(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "hdrs" => $0 }
    }

    static func hdrs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "hdrs" => $0 }
    }

    static func header_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "header_name" => $0 }
    }

    static func includes(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "includes" => $0 }
    }

    static func infoplists(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "infoplists" => $0 }
    }

    static func interface_library(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "interface_library" => $0 }
    }

    static func jre_deps(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "jre_deps" => $0 }
    }

    static func language(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "language" => $0 }
    }

    static func linkopts(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "linkopts" => $0 }
    }

    static func linkstatic(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "linkstatic" => $0 }
    }

    static func local_versions(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "local_versions" => $0 }
    }

    static func make_variable(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "make_variable" => $0 }
    }

    static func match_all(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "match_all" => $0 }
    }

    static func match_any(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "match_any" => $0 }
    }

    static func minimum_deployment_os_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "minimum_deployment_os_version" => $0 }
    }

    static func minimum_os_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "minimum_os_version" => $0 }
    }

    static func minimum_os_versions(_ value: [String: String]?) -> Starlark.Statement.Argument? {
        value.map { "minimum_os_versions" => $0 }
    }

    static func module_map(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "module_map" => $0 }
    }

    static func module_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "module_name" => $0 }
    }

    static func name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "name" => $0 }
    }

    static func non_arc_srcs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "non_arc_srcs" => $0 }
    }

    static func os_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "os_version" => $0 }
    }

    static func out(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "out" => $0 }
    }

    static func outs(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "outs" => $0 }
    }

    static func overlay_deps(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "overlay_deps" => $0 }
    }

    static func package_groups(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "package_groups" => $0 }
    }

    static func package_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "package_name" => $0 }
    }

    static func pch(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "pch" => $0 }
    }

    static func platform(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "platform" => $0 }
    }

    static func platform_type(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "platform_type" => $0 }
    }

    static func plugin(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "plugin" => $0 }
    }

    static func plugins(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "plugins" => $0 }
    }

    static func primary_app_icon(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "primary_app_icon" => $0 }
    }

    static func private_deps(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "private_deps" => $0 }
    }

    static func product_family(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "product_family" => $0 }
    }

    static func profile_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "profile_name" => $0 }
    }

    static func provisioning_profile(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "provisioning_profile" => $0 }
    }

    static func public_hdrs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "public_hdrs" => $0 }
    }

    static func remote_versions(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "remote_versions" => $0 }
    }

    static func repo_name(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "repo_name" => $0 }
    }

    static func resources(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "resources" => $0 }
    }

    static func runner(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "runner" => $0 }
    }

    static func runners(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "runners" => $0 }
    }

    static func runtime_platform(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "runtime_platform" => $0 }
    }

    static func scope(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "scope" => $0 }
    }

    static func sdk_dylibs(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "sdk_dylibs" => $0 }
    }

    static func sdk_frameworks(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "sdk_frameworks" => $0 }
    }

    static func sdk_includes(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "sdk_includes" => $0 }
    }

    static func shared_library(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "shared_library" => $0 }
    }

    static func short_version_string(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "short_version_string" => $0 }
    }

    static func src(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "src" => $0 }
    }

    static func srcs(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "srcs" => $0 }
    }

    static func srcs(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "srcs" => $0 }
    }

    static func srcs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "srcs" => $0 }
    }

    static func stamp(_ value: Int?) -> Starlark.Statement.Argument? {
        value.map { "stamp" => $0 }
    }

    static func static_library(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "static_library" => $0 }
    }

    static func sticker_assets(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "sticker_assets" => $0 }
    }

    static func strings(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "strings" => $0 }
    }

    static func strip_structured_resources_prefixes(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "strip_structured_resources_prefixes" => $0 }
    }

    static func structured_resources(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "structured_resources" => $0 }
    }

    static func suppressed(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "suppressed" => $0 }
    }

    static func swift_copts(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "swift_copts" => $0 }
    }

    static func swift_defines(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "swift_defines" => $0 }
    }

    static func swift_plugins(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "swift_plugins" => $0 }
    }

    static func swift_srcs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "swift_srcs" => $0 }
    }

    static func swift_version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "swift_version" => $0 }
    }

    static func swiftc_inputs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "swiftc_inputs" => $0 }
    }

    static func swiftdoc(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "swiftdoc" => $0 }
    }

    static func swiftinterface(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "swiftinterface" => $0 }
    }

    static func swiftmodule(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "swiftmodule" => $0 }
    }

    static func system_provided(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "system_provided" => $0 }
    }

    static func tags(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "tags" => $0 }
    }

    static func target(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "target" => $0 }
    }

    static func target_compatible_with(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "target_compatible_with" => $0 }
    }

    static func targets(_ value: [Starlark.Label]?) -> Starlark.Statement.Argument? {
        value.map { "targets" => $0 }
    }

    static func teamid(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "teamid" => $0 }
    }

    static func template(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "template" => $0 }
    }

    static func test_bundle(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "test_bundle" => $0 }
    }

    static func test_filter(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "test_filter" => $0 }
    }

    static func test_host(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "test_host" => $0 }
    }

    static func testonly(_ value: Bool?) -> Starlark.Statement.Argument? {
        value.map { "testonly" => $0 }
    }

    static func textual_hdrs(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "textual_hdrs" => $0 }
    }

    static func timeout(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "timeout" => $0 }
    }

    static func toolchain_types(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "toolchain_types" => $0 }
    }

    static func umbrella_header(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "umbrella_header" => $0 }
    }

    static func values(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "values" => $0 }
    }

    static func values(_ value: [String: String]?) -> Starlark.Statement.Argument? {
        value.map { "values" => $0 }
    }

    static func version(_ value: String?) -> Starlark.Statement.Argument? {
        value.map { "version" => $0 }
    }

    static func versions(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "versions" => $0 }
    }

    static func visibility(_ value: Starlark.Statement.Argument.Visibility?) -> Starlark.Statement.Argument? {
        value?.argument
    }

    static func watch_application(_ value: Starlark.Label?) -> Starlark.Statement.Argument? {
        value.map { "watch_application" => $0 }
    }

    static func weak_sdk_frameworks(_ value: [String]?) -> Starlark.Statement.Argument? {
        value.map { "weak_sdk_frameworks" => $0 }
    }

    static func xcframework_imports(_ value: Starlark.Value?) -> Starlark.Statement.Argument? {
        value.map { "xcframework_imports" => $0 }
    }
}
