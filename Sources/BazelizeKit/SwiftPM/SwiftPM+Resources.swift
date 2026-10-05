//
//  SwiftPM+Resources.swift
//
//
//  A package target's resources, as a bundle plus the accessor that finds it.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// What a target's resources add to its own rule.
    struct ResourceBundle {
        /// The rule the library carries as `data`, absent when the target's only
        /// resources are embedded in its code.
        let label: String?
        /// Generated sources compiled into the library: the accessor a package's
        /// own code calls to reach its bundle, and the bytes of what it embeds.
        let accessors: [String]
        /// The header a C-family target force-includes, so `SWIFTPM_MODULE_BUNDLE`
        /// resolves without the sources importing anything.
        let header: String?
    }

    /// The resources of one target, or `nil` when it has none.
    ///
    /// SwiftPM puts a target's resources in a bundle named `<Package>_<Target>`
    /// and compiles an accessor that finds it at runtime; a package reaches its
    /// own resources only through that pair, so both are generated here.
    ///
    /// `generated` are the files a build tool plugin produced that the target
    /// does not compile. SwiftPM bundles those the same way, so a target whose
    /// only resources come from a plugin still gets a bundle.
    func buildResources(
        _ target: SwiftPM.PackageTarget,
        in package: SwiftPM.Package,
        prefix: String,
        root: Path,
        kind: TargetKind,
        generated: [String],
        builder: CodeBuilder) throws -> ResourceBundle?
    {
        guard let directory = sourceDirectory(of: target, in: package) else { return nil }

        let files = relativeFiles(of: target, in: package, prefix: prefix)

        /// `.copy` keeps the item's own name and inner structure and nothing above
        /// it, which is a structured resource with the path above the item stripped;
        /// `.process` lets the bundler place each file. `.embedInCode` is not
        /// bundled at all.
        var resources: [String] = []
        var copied: [String: [String]] = [:]
        var embedded: [String] = []
        var explicitlyDeclared: Set<String> = []
        for resource in target.resources {
            let pattern = Self.pattern(of: resource.path, in: directory, prefix: prefix)
            explicitlyDeclared.formUnion(files.filter { Self.matches(pattern, $0) })
            if resource.isEmbedInCode {
                embedded.append(resource.path)
            } else if resource.isCopy {
                let above = Path("\(prefix)/\(resource.path)").parent().normalize().string
                copied[above, default: []].append(pattern)
            } else {
                resources.append(pattern)
            }
        }

        Self.copyUndeclaredPrivacyManifests(
            in: files,
            excluding: explicitlyDeclared,
            into: &copied)
        resources = matching(resources, files)
            + matching(Self.discoveredResources(prefix: prefix), files)
            /// A plugin's output is named as it was found on disk, so it needs no
            /// matching against the target's own files.
            + generated
        let structured = copied
            .mapValues { matching($0, files) }
            .filter { !$0.value.isEmpty }

        /// A shader compiles like any other source: it includes the target's
        /// headers, so they belong to the same resource group. The bundler treats a
        /// bundled header as a Metal header and compiles it into the library
        /// instead of copying it.
        if resources.contains(where: { $0.hasSuffix(".metal") }) {
            resources += matching(
                SwiftPM.Generator.headerExtensions.map { "\(prefix)/**/*.\($0)" },
                relativeFiles(of: target, in: package, prefix: prefix, excluding: false))
        }

        /// What is embedded is compiled, not bundled, so it is the one kind of
        /// resource a target can have without having a bundle.
        let embeddedSource = try Self.embed(embedded, of: target, in: directory, root: root, kind: kind)

        /// A declared resource that is not on disk leaves nothing to bundle, and a
        /// bundle rule without resources is an empty bundle.
        guard !resources.isEmpty || !structured.isEmpty else {
            return embeddedSource.map {
                ResourceBundle(label: nil, accessors: [$0], header: nil)
            }
        }

        let bundle = "\(package.manifest.name)_\(target.name)"
        let name = "\(ruleName(of: target.name, in: package))Resources"
        try (root + "Generated").mkpath()

        let plist = "Generated/\(target.name)ResourceBundle-Info.plist"
        try (root + plist).write(Self.infoPlist(bundle: bundle))

        /// One group per directory a copied item sits in: the group is what can say
        /// how much of the path to drop, so the item lands at the bundle's root the
        /// way SwiftPM copies it.
        var groups: [String] = []

        /// Processed resources join the groups when there is one, so the bundle's
        /// attribute stays one kind of thing.
        if !structured.isEmpty, let patterns = resources.nonEmpty {
            let group = "\(name)Processed"
            groups.append(group)

            builder.load(loadableRule: Rules.Apple.Resources.apple_resource_group)
            builder.call(
                Rules.Apple.Resources.Call.apple_resource_group(
                    name: group,
                    resources: self.files(matching: patterns, allowEmpty: true)))
        }

        for (index, prefixToStrip) in structured.keys.sorted().enumerated() {
            guard let patterns = structured[prefixToStrip] else { continue }

            let group = "\(name)Copied\(index)"
            groups.append(group)

            builder.load(loadableRule: Rules.Apple.Resources.apple_resource_group)
            builder.call(
                Rules.Apple.Resources.Call.apple_resource_group(
                    name: group,
                    strip_structured_resources_prefixes: [prefixToStrip],
                    structured_resources: self.files(matching: patterns)))
        }

        let resourceInputs: Starlark.Value? = groups.isEmpty
            ? resources.nonEmpty.map { self.files(matching: $0, allowEmpty: true) }
            : .build { groups.map { Starlark.Label.named(":\($0)") } }

        let executableMinimumOS: String?
        if case .executable = kind {
            executableMinimumOS = deployment.required(package, platform: "macos")
        } else {
            executableMinimumOS = nil
        }
        emit(
            ResourceRule(
                name: name,
                bundle: bundle,
                plist: plist,
                resources: resourceInputs),
            executableMinimumOS: executableMinimumOS,
            builder: builder)

        return try Self.resourceBundle(
            ResourceResult(
                target: target.name,
                package: package.directory,
                bundle: bundle,
                label: ":\(name)",
                root: root,
                kind: kind,
                embeddedSource: embeddedSource))
    }

    /// Adds SwiftPM's implicit privacy manifest with `.copy` semantics. A
    /// declared file or containing directory already owns the manifest.
    private static func copyUndeclaredPrivacyManifests(
        in files: [String],
        excluding declared: Set<String>,
        into copied: inout [String: [String]])
    {
        for manifest in files
            where Path(manifest).lastComponent == "PrivacyInfo.xcprivacy"
            && !declared.contains(manifest)
        {
            copied[Path(manifest).parent().normalize().string, default: []].append(manifest)
        }
    }

    /// Writes the language-specific accessor and describes what the target carries.
    private static func resourceBundle(_ result: ResourceResult) throws -> ResourceBundle? {
        switch result.kind {
        case .executable:
            let accessor = "Generated/\(result.target)ResourceBundleAccessor.swift"
            try (result.root + accessor).write(
                swiftAccessor(
                    bundle: result.bundle,
                    runfilesPath: "Packages/\(result.package)/\(result.bundle).bundle"))
            return ResourceBundle(
                label: result.label,
                accessors: [accessor] + (result.embeddedSource.map { [$0] } ?? []),
                header: nil)
        case .swift, .test:
            let accessor = "Generated/\(result.target)ResourceBundleAccessor.swift"
            try (result.root + accessor).write(swiftAccessor(bundle: result.bundle))
            return ResourceBundle(
                label: result.label,
                accessors: [accessor] + (result.embeddedSource.map { [$0] } ?? []),
                header: nil)
        case .clang:
            let module = moduleName(result.target)
            let header = "Generated/\(result.target)ResourceBundleAccessor.h"
            let implementation = "Generated/\(result.target)ResourceBundleAccessor.m"
            try (result.root + header).write(objcAccessorHeader(module: module))
            try (result.root + implementation).write(
                objcAccessor(module: module, bundle: result.bundle))
            return ResourceBundle(
                label: result.label,
                accessors: [header, implementation],
                header: header)
        case .binary, .system, .macro, .unsupported:
            return nil
        }
    }

    /// `.embedInCode`: the bytes of each file, as the source SwiftPM compiles in
    /// place of bundling them.
    ///
    /// Only Swift reads it — SwiftPM generates Swift, and names each file's
    /// array after the file — so a C-family target embedding something gets
    /// nothing here, the same as from SwiftPM.
    private static func embed(
        _ paths: [String],
        of target: SwiftPM.PackageTarget,
        in directory: Path,
        root: Path,
        kind: TargetKind) throws -> String?
    {
        guard !paths.isEmpty else { return nil }
        switch kind {
        case .swift, .executable, .test: break
        case .clang, .binary, .system, .macro, .unsupported: return nil
        }

        var arrays: [String] = []
        for path in paths.sorted() {
            let file = directory + Path(path)
            guard file.isFile, let bytes = try? Data(contentsOf: file.url) else { continue }
            let name = identifier(of: file.lastComponent)
            arrays.append("static let \(name): [UInt8] = [\(bytes.map(String.init).joined(separator: ","))]")
        }
        guard !arrays.isEmpty else { return nil }

        let source = "Generated/\(target.name)EmbeddedResources.swift"
        try (root + "Generated").mkpath()
        try (root + source).write("""
        struct PackageResources {
        \(arrays.joined(separator: "\n"))
        }

        """)
        return source
    }

    /// A file's name as SwiftPM names its array: what cannot be in an identifier
    /// is an underscore.
    private static func identifier(of name: String) -> String {
        let mangled = String(name.map { character in
            character.isLetter || character.isNumber || character == "_" ? character : "_"
        })
        return mangled.first?.isNumber == true ? "_\(mangled)" : mangled
    }

    /// The resource types SwiftPM treats as resources without being told, so a
    /// package that ships a xib and declares nothing still gets a bundle.
    private static func discoveredResources(prefix: String) -> [String] {
        discoveredExtensions.map { "\(prefix)/**/*.\($0)" }
            /// A catalog or a model is a directory, so what a glob can name is the
            /// files inside it — as is a `.lproj` directory, which makes every file
            /// in it a localized resource whatever its own type is.
            + (discoveredDirectoryExtensions + ["lproj"]).map { "\(prefix)/**/*.\($0)/**" }
    }

    /// The file types SwiftPM turns into resources on its own, from its own file
    /// rules.
    private static let discoveredExtensions = [
        "nib",
        "xib",
        "storyboard",
        "xcstrings",
        "metal",
    ]

    private static let discoveredDirectoryExtensions = [
        "xcassets",
        "xcdatamodel",
        "xcdatamodeld",
        "xcmappingmodel",
    ]

    /// A resource path is a file or a directory; a directory contributes
    /// everything under it.
    private static func pattern(of path: String, in directory: Path, prefix: String) -> String {
        (directory + path).isDirectory
            ? "\(prefix)/\(path)/**"
            : "\(prefix)/\(path)"
    }

    /// The bundle SwiftPM produces carries an `Info.plist`; without one the bundle
    /// is not loadable.
    private static func infoPlist(bundle: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>org.swift.\(bundle)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>\(bundle)</string>
            <key>CFBundlePackageType</key>
            <string>BNDL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
        </dict>
        </plist>

        """
    }

    /// The C-family half of the same accessor. SwiftPM force-includes this header
    /// into every source of the target, which is how `SWIFTPM_MODULE_BUNDLE`
    /// appears without an import.
    private static func objcAccessorHeader(module: String) -> String {
        """
        #ifdef __OBJC__
        #import <Foundation/Foundation.h>

        #if __cplusplus
        extern "C" {
        #endif

        NSBundle *\(module)_SWIFTPM_MODULE_BUNDLE(void);

        #define SWIFTPM_MODULE_BUNDLE \(module)_SWIFTPM_MODULE_BUNDLE()

        #if __cplusplus
        }
        #endif
        #endif

        """
    }

    private static func objcAccessor(module: String, bundle: String) -> String {
        """
        #import <Foundation/Foundation.h>

        @interface \(module)_BundleFinder : NSObject
        @end

        @implementation \(module)_BundleFinder
        @end

        NSBundle *\(module)_SWIFTPM_MODULE_BUNDLE(void) {
            /// The same candidates the Swift accessor tries, in the same
            /// order: on macOS a bundle's resources are under `Resources`, and
            /// only a flat bundle has them beside the binary.
            NSArray<NSURL *> *candidates = @[
                [[NSBundle mainBundle] resourceURL] ?: [[NSBundle mainBundle] bundleURL],
                [[NSBundle bundleForClass:[\(module)_BundleFinder class]] resourceURL]
                    ?: [[NSBundle bundleForClass:[\(module)_BundleFinder class]] bundleURL],
                [[NSBundle mainBundle] bundleURL],
            ];

            for (NSURL *base in candidates) {
                NSURL *url = [base URLByAppendingPathComponent:@"\(bundle).bundle"];
                NSBundle *found = [NSBundle bundleWithURL:url];
                if (found != nil) {
                    return found;
                }
            }

            return nil;
        }

        """
    }
}
