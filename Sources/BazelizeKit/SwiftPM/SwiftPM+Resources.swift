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
        /// The rule the library carries as `data`.
        let label: String
        /// Generated sources compiled into the library: the accessor a package's
        /// own code calls to reach its bundle.
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
        /// `.process` lets the bundler place each file.
        var resources: [String] = []
        var copied: [String: [String]] = [:]
        for resource in target.resources {
            let pattern = Self.pattern(of: resource.path, in: directory, prefix: prefix)
            if resource.isCopy {
                let above = Path("\(prefix)/\(resource.path)").parent().normalize().string
                copied[above, default: []].append(pattern)
            } else {
                resources.append(pattern)
            }
        }
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

        /// A declared resource that is not on disk leaves nothing to bundle, and a
        /// bundle rule without resources is an empty bundle.
        guard !resources.isEmpty || !structured.isEmpty else { return nil }

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
                    resources: Starlark.glob(patterns, allowEmpty: true)))
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
                    structured_resources: Starlark.glob(patterns)))
        }

        builder.load(loadableRule: Rules.Apple.Resources.apple_resource_bundle)
        builder.call(
            Rules.Apple.Resources.Call.apple_resource_bundle(
                name: name,
                bundle_name: bundle,
                infoplists: .build { [Starlark.Label.named(plist)] },
                /// A glob and a group cannot be added together in one attribute, so
                /// once there is a group everything is a group.
                resources: groups.isEmpty
                    ? resources.nonEmpty.map { Starlark.glob($0, allowEmpty: true) }
                    : .build { groups.map { Starlark.Label.named(":\($0)") } },
                tags: Self.manual))

        switch kind {
        case .swift, .executable, .test:
            let accessor = "Generated/\(target.name)ResourceBundleAccessor.swift"
            try (root + accessor).write(Self.swiftAccessor(bundle: bundle))
            return ResourceBundle(label: ":\(name)", accessors: [accessor], header: nil)
        case .clang:
            let module = Self.moduleName(target.name)
            let header = "Generated/\(target.name)ResourceBundleAccessor.h"
            let implementation = "Generated/\(target.name)ResourceBundleAccessor.m"
            try (root + header).write(Self.objcAccessorHeader(module: module))
            try (root + implementation).write(
                Self.objcAccessor(module: module, bundle: bundle))
            return ResourceBundle(
                label: ":\(name)",
                accessors: [header, implementation],
                header: header)
        case .binary, .system, .macro, .unsupported:
            return nil
        }
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

    /// `Bundle.module`, the name a package's Swift code uses.
    ///
    /// The bundle sits next to the binary that linked the package, and which
    /// binary that is depends on whether the package went into an app, a
    /// framework or a tool — so every candidate is tried.
    private static func swiftAccessor(bundle: String) -> String {
        """
        import Foundation

        private final class BundleFinder {}

        extension Foundation.Bundle {
            static let module: Bundle = {
                let candidates = [
                    Bundle.main.resourceURL,
                    Bundle(for: BundleFinder.self).resourceURL,
                    Bundle.main.bundleURL,
                ]

                for candidate in candidates {
                    let url = candidate?.appendingPathComponent("\(bundle).bundle")
                    if let bundle = url.flatMap(Bundle.init(url:)) {
                        return bundle
                    }
                }

                fatalError("unable to find bundle named \(bundle)")
            }()
        }

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
            NSArray *candidates = @[
                [[NSBundle mainBundle] bundleURL],
                [[NSBundle bundleForClass:[\(module)_BundleFinder class]] bundleURL],
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
