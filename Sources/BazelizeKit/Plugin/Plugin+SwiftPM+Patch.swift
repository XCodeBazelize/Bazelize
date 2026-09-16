//
//  Plugin+SwiftPM+Patch.swift
//
//
//  Patches for rules_swift_package_manager, applied to the generated workspace.
//
import Util

extension PluginSwiftPM {
    /// Files rules_swift_package_manager generates for a package are incomplete in
    /// ways that keep real projects from building, and no amount of code generation
    /// on this side can make up for them. They are patched in the generated
    /// workspace so it stands on its own; all of it belongs upstream.
    static let patchDirectory = "Patches"

    /// The release the patches were written against.
    ///
    /// A patch is a diff, so it only applies to the file it was taken from: for any
    /// other release the workspace is generated without it, and whatever the newer
    /// release does — fixed upstream or still broken — is what the build sees.
    static let patchedVersion: BazelDep.SwiftPM = .v1_15_0

    private static let allPatches: [(name: String, content: String)] = [
        (name: "rspm-clang-target-headers.patch", content: clangTargetHeadersPatch),
        (name: "rspm-metal-headers.patch", content: metalHeadersPatch),
        (name: "rspm-default-isolation-settings.patch", content: defaultIsolationSettingsPatch),
        (name: "rspm-default-isolation-copts.patch", content: defaultIsolationCoptsPatch),
        (name: "rspm-local-archive-artifact.patch", content: localArchiveArtifactPatch)
    ]

    var patches: [(name: String, content: String)] {
        guard dep == Self.patchedVersion else {
            let pinned = dep.rawValue
            let patched = Self.patchedVersion.rawValue
            Log.codeGenerate.warning("""
            rules_swift_package_manager \(pinned, privacy: .public) is not \
            \(patched, privacy: .public): generating without the patches written for it
            """)
            return []
        }
        return Self.allPatches
    }

    /// The `patches` attribute of the module override.
    var patchLabels: String {
        patches.map { patch in
            "        \"//\(Self.patchDirectory):\(patch.name)\","
        }.joined(separator: "\n")
    }

    /// The patch files themselves, plus the package that exports them.
    var patchFiles: [PluginBuiltin.Custom] {
        guard !patches.isEmpty else { return [] }

        let patchDirectory = Self.patchDirectory
        let exports = patches.map { patch in
            "    \"\(patch.name)\","
        }.joined(separator: "\n")

        let build = PluginBuiltin.Custom(
            path: "\(patchDirectory)/BUILD",
            content: """
            exports_files([
            \(exports)
            ])
            """)

        return [build] + patches.map { patch in
            PluginBuiltin.Custom(path: "\(patchDirectory)/\(patch.name)", content: patch.content)
        }
    }

    /// A clang target that lists its sources explicitly loses every header that is
    /// not a declared source or a public header, so a source including one by
    /// relative path cannot compile in a sandbox.
    ///
    /// Example: tree-sitter-typescript, where `tsx/src/scanner.c` includes
    /// `../../common/scanner.h`.
    private static let clangTargetHeadersPatch = #"""
--- a/swiftpkg/internal/pkginfos.bzl
+++ b/swiftpkg/internal/pkginfos.bzl
@@ -1502,6 +1502,23 @@
             exclude_paths = abs_exclude_paths,
         ))
 
+    # A manifest that lists its sources explicitly still lets clang read any
+    # header under the target path: a source can include one by relative path
+    # without a header search path pointing at it. SPM compiles such a target
+    # straight out of the checkout, so nothing has to be declared; Bazel only
+    # stages declared files, so the headers are collected here.
+    # Example: tree-sitter-typescript, where `tsx/src/scanner.c` includes
+    # `../../common/scanner.h`.
+    if source_paths != None:
+        for f in repository_files.list_files_under(
+            repository_ctx,
+            abs_target_path,
+            exclude_paths = abs_exclude_paths,
+        ):
+            _, hdr_ext = paths.split_extension(f)
+            if hdr_ext in _HEADER_EXTS:
+                all_srcs.append(f)
+
     # SPM's exclude list only excludes files from being compiled as sources,
     # but headers in excluded directories are still available for inclusion.
     # We need to find all header files in excluded directories and add them
"""#

    /// A `.metal` resource is compiled, and the shader includes a header of its own
    /// target, which the generated resource bundle does not carry. rules_apple
    /// already treats a header in the same resource group as a metal include.
    ///
    /// Example: UTM's CocoaSpice, where `CSShaders.metal` includes
    /// `include/CSShaderTypes.h`.
    private static let metalHeadersPatch = #"""
--- a/swiftpkg/internal/swiftpkg_build_files.bzl
+++ b/swiftpkg/internal/swiftpkg_build_files.bzl
@@ -930,6 +930,20 @@
         for r in sorted_resources
         if not r.endswith(".bundle")
     ]
+
+    # A `.metal` resource is compiled, not copied, and a shader routinely
+    # includes a header that is part of the target. rules_apple passes any
+    # header in the same resource group to `metal` as an input and does not
+    # bundle it, so the target's headers go in alongside the shaders.
+    if lists.contains([r.endswith(".metal") for r in resources], True):
+        clang_src_info = getattr(target, "clang_src_info", None)
+        if clang_src_info != None:
+            hdrs = [
+                hdr
+                for hdr in clang_src_info.hdrs + clang_src_info.textual_hdrs
+                if hdr.endswith(".h") and not lists.contains(resources, hdr)
+            ]
+            resources = resources + sorted(hdrs)
     precompiled_bundles_and_labels = [
         (r, "{}_{}".format(bundle_label_name, _sanitized_bundle_file_name(r.split("/")[-1])))
         for r in sorted_resources
"""#

    /// `SwiftSetting.defaultIsolation` (SE-0466) is parsed and then dropped as an
    /// unrecognized setting, so a package written against `MainActor` by default
    /// does not compile. Bazel applies one patch per file, so the setting and the
    /// flag it maps to come as a pair.
    ///
    /// Example: IceCubesApp, whose local packages all declare it.
    private static let defaultIsolationSettingsPatch = #"""
--- a/swiftpkg/internal/pkginfos.bzl
+++ b/swiftpkg/internal/pkginfos.bzl
@@ -1862,6 +1879,7 @@
     language_modes = []
     experimental_features = []
     upcoming_features = []
+    default_isolations = []
     for bs in build_settings:
         if bs.kind == build_setting_kinds.define:
             defines.append(bs)
@@ -1873,6 +1891,8 @@
             experimental_features.append(bs)
         elif bs.kind == build_setting_kinds.upcoming_features:
             upcoming_features.append(bs)
+        elif bs.kind == build_setting_kinds.default_isolation:
+            default_isolations.append(bs)
         else:
             # We do not recognize the setting.
             pass
@@ -1880,7 +1900,8 @@
        len(unsafe_flags) == 0 and \
        len(language_modes) == 0 and \
        len(experimental_features) == 0 and \
-       len(upcoming_features) == 0:
+       len(upcoming_features) == 0 and \
+       len(default_isolations) == 0:
         return None
     return struct(
         defines = defines,
@@ -1888,6 +1909,7 @@
         language_modes = language_modes,
         experimental_features = experimental_features,
         upcoming_features = upcoming_features,
+        default_isolations = default_isolations,
     )
 
 def _new_linker_settings(build_settings):
@@ -2083,6 +2105,7 @@
 )
 
 build_setting_kinds = struct(
+    default_isolation = "defaultIsolation",
     define = "define",
     header_search_path = "headerSearchPath",
     linked_framework = "linkedFramework",
"""#

    /// The other half: `swiftc`'s `-default-isolation`.
    private static let defaultIsolationCoptsPatch = #"""
--- a/swiftpkg/internal/swiftpkg_build_files.bzl
+++ b/swiftpkg/internal/swiftpkg_build_files.bzl
@@ -176,6 +176,20 @@
                     condition = experimental_feature.condition,
                 )
                 features.append(new_experimental_feature)
+        for bs in target.swift_settings.default_isolations:
+            for default_isolation in lists.flatten(bzl_selects.new_from_build_setting(bs)):
+                # SE-0466: the manifest setting maps to the compiler flag that
+                # controls the module's default actor isolation.
+                copts.append(bzl_selects.new(
+                    value = "-default-isolation",
+                    kind = default_isolation.kind,
+                    condition = default_isolation.condition,
+                ))
+                copts.append(bzl_selects.new(
+                    value = default_isolation.value,
+                    kind = default_isolation.kind,
+                    condition = default_isolation.condition,
+                ))
         for bs in target.swift_settings.upcoming_features:
             for upcoming_feature in lists.flatten(bzl_selects.new_from_build_setting(bs)):
                 new_upcoming_feature = bzl_selects.new(
"""#

    /// A binary target whose `path` points at an archive in the checkout is ignored:
    /// the artifact scan looks for a directory, finds nothing and generates no
    /// target, while the package's own products still depend on it. SPM unzips such
    /// an archive itself.
    ///
    /// Example: CodeEditLanguages, which ships
    /// `CodeLanguagesContainer.xcframework.zip`.
    private static let localArchiveArtifactPatch = #"""
--- a/swiftpkg/internal/repo_rules.bzl
+++ b/swiftpkg/internal/repo_rules.bzl
@@ -151,6 +151,14 @@
     repository_ctx.file(path, content = content, executable = False)
 
 def _artifact_infos_from_path(repository_ctx, path):
+    # A binary target can point at an archive in the checkout, which SPM unzips
+    # itself; nothing in it is visible until it is extracted.
+    if path.endswith(".zip") and not repository_files.is_directory(repository_ctx, path):
+        output = path + ".extracted"
+        if not repository_files.path_exists(repository_ctx, output):
+            repository_ctx.extract(archive = path, output = output)
+        path = output
+
     if path.endswith(".xcframework"):
         xcframework_dirs = [path]
     else:
"""#
}
