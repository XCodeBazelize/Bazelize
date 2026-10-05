# Bazel Rules

 * [rules_apple](https://github.com/bazelbuild/rules_apple/tree/master/doc)
    * [rules](https://github.com/bazelbuild/rules_apple/tree/master/doc) —
      main rules such as `ios_application` / `ios_framework` / `macos_bundle`.
    * [frameworks](https://github.com/bazelbuild/rules_apple/blob/master/doc/frameworks.md)
        * prebuilt
          `apple_dynamic_framework_import` (`.framework`)  
          `apple_dynamic_xcframework_import` (`.xcframework` from `Xcode`)  
          `apple_static_xcframework_import` (`SwiftPM` binary target)  
          `apple_static_framework_import` (defined in `Rules.Apple`, but no generator emits it yet)
    * [resources](https://github.com/bazelbuild/rules_apple/blob/master/doc/resources.md)
 * [rules_swift](https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md)
    * `swift_library` / `swift_library_group` / `swift_binary` / `swift_interop_hint`
    * `mixed_language_library` — used when one target mixes C-family and Swift sources.
 * [rules_cc](https://github.com/bazelbuild/rules_cc) — `objc_library`, `cc_library`, `cc_import`
   (`objc_library` is also loaded from `@rules_cc//cc:defs.bzl`).
 * [bazel_skylib](https://github.com/bazelbuild/bazel-skylib)
    * [common_settings](https://github.com/bazelbuild/bazel-skylib/blob/main/docs/common_settings_doc.md) —
      `string_flag`, combined with the builtin `config_setting` to form `Debug`/`Release`.
    * [selects](https://github.com/bazelbuild/bazel-skylib/blob/main/docs/selects_doc.md) —
      `selects.config_setting_group`, used for `SwiftPM` trait/platform conditions.
    * [native_binary](https://github.com/bazelbuild/bazel-skylib/blob/main/docs/native_binary_doc.md) —
      executable `SwiftPM` binary targets.
 * [rules_shell](https://github.com/bazelbuild/rules_shell) — `sh_binary` (`lint`/`format`/`plugins`).
 * [Plist](https://github.com/imWildCat/MinimalBazelFrameworkDemo) — `plist_fragment`, used to generate `Info.plist`.
 * [rules_xcodeproj](https://github.com/MobileNativeFoundation/rules_xcodeproj) — `xcodeproj`.
 * [apple_support](https://github.com/bazelbuild/apple_support) — Apple toolchain,
   and constraints such as `@apple_support//constraints:catalyst`.
 * [platforms](https://github.com/bazelbuild/platforms) — `@platforms//os:<name>` constraints.
 * [rules_apple_linker](https://github.com/keith/rules_apple_linker) — optional `zld`/`lld` linker plugin.
