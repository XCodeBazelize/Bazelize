//
//  SwiftPM+Plugin.swift
//
//
//  The sources a build tool plugin generates.
//

import Foundation
@preconcurrency import PathKit

extension SwiftPM {
    /// What a build tool plugin produced, by target.
    ///
    /// bazelize is the plugin's host: it compiles the plugin, hands it the
    /// package graph and a directory to write into, and runs the commands the
    /// plugin asks for. Where the files go is the host's decision — the
    /// package's own `Generated/<Target>Plugin` — and what they are called is
    /// the plugin's.
    ///
    /// The consequence is the one every generated file here has: they change
    /// when bazelize runs again, not when the input changes. Only a package in
    /// the project's own repository is run, because a plugin's tool still has to
    /// be built, and building one for every dependency that merely lints would
    /// make generating a workspace cost a full build.
    struct PluginOutputs: Sendable {
        /// What one target's plugins wrote, and the directory they wrote it
        /// into: two plugins of the same target write into a directory each, and
        /// a prebuild command writes a tree, so a file is only named by where it
        /// sits under that root.
        struct Output: Sendable {
            let root: Path
            let files: [Path]
        }

        /// What kept a plugin from producing what a target expects, for the run
        /// to say out loud: the compile error a missing generated file causes
        /// names the file, never the plugin.
        let notes: [String]

        /// Keyed `<package directory>/<target>`.
        private let outputs: [String: Output]

        init(outputs: [String: Output] = [:], notes: [String] = []) {
            self.outputs = outputs
            self.notes = notes
        }

        func output(of target: String, in package: Package) -> Output? {
            outputs["\(package.directory)/\(target)"]
        }
    }
}
