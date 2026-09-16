//
//  Plugin+SwiftPM+Patch.swift
//
//
//  Patches for rules_swift_package_manager, applied to the generated workspace.
//

extension PluginSwiftPM {
    /// Files rules_swift_package_manager generates for a package are incomplete in
    /// two ways that keep real projects from building. Both are patched in the
    /// generated workspace so it stands on its own; both belong upstream.
    static let patchDirectory = "Patches"

    static let patches: [(name: String, content: String)] = [
        (name: "rspm-clang-target-headers.patch", content: clangTargetHeadersPatch),
        (name: "rspm-metal-headers.patch", content: metalHeadersPatch)
    ]

    /// The `patches` attribute of the module override.
    static var patchLabels: String {
        patches.map { patch in
            "        \"//\(patchDirectory):\(patch.name)\","
        }.joined(separator: "\n")
    }

    /// The patch files themselves, plus the package that exports them.
    static var patchFiles: [PluginBuiltin.Custom] {
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
}
