import Foundation

// MARK: - Xcode.TargetSummaryFormatter

extension Xcode {
    public enum TargetSummaryFormatter {
        public static func format(project: Xcode.Project, target: Xcode.Target) -> String {
            var lines: [String] = []

            lines.append("Target: \(target.name)")
            lines.append("Type: \(target.productType ?? "<unknown>")")

            if let productName = target.productName {
                lines.append("Product Name: \(productName)")
            }

            lines.append("")
            lines.append("Metadata:")
            appendValue(target.metadata.bundleID, label: "Bundle ID", to: &lines)
            appendValue(target.metadata.moduleName, label: "Module Name", to: &lines)
            appendValue(target.metadata.infoPlist, label: "Info.plist", to: &lines)

            if !target.metadata.deploymentTargets.isEmpty {
                lines.append("  Deployment Targets:")
                for key in target.metadata.deploymentTargets.keys.sorted() {
                    guard let value = target.metadata.deploymentTargets[key] else { continue }
                    lines.append("    \(key): \(value)")
                }
            }

            appendValue(target.metadata.codeSign.codeSignStyle, label: "Code Sign Style", to: &lines)
            appendValue(target.metadata.codeSign.developmentTeam, label: "Development Team", to: &lines)
            appendValue(target.metadata.codeSign.codeSignIdentity, label: "Code Sign Identity", to: &lines)

            lines.append("")
            lines.append("Files:")
            appendFiles(target.files.sources, title: "Sources", to: &lines)
            appendFiles(target.files.headers, title: "Headers", to: &lines)
            appendFiles(target.files.resources, title: "Resources", to: &lines)
            appendFiles(target.files.frameworks, title: "Frameworks", to: &lines)
            appendFiles(target.files.copyFiles, title: "Copy Files", to: &lines)
            appendFiles(target.files.others, title: "Others", to: &lines)

            lines.append("")
            lines.append("Dependencies:")
            appendList(target.dependencies.targets, title: "Targets", to: &lines)
            appendList(target.dependencies.packageProducts.map(\.summaryText), title: "Package Products", to: &lines)
            appendList(target.dependencies.frameworks, title: "Frameworks", to: &lines)
            appendList(target.dependencies.sdkFrameworks, title: "SDK Frameworks", to: &lines)

            let selectedConfigName = project.preferConfig ?? target.configs.keys.sorted().first
            if let selectedConfigName, let settings = target.configs[selectedConfigName] {
                lines.append("")
                lines.append("Settings [\(selectedConfigName)]:")
                for key in settings.keys.sorted() {
                    guard let value = settings[key] else { continue }
                    lines.append("  \(key) = \(value)")
                }
            }

            return lines.joined(separator: "\n")
        }

        private static func appendValue(_ value: String?, label: String, to lines: inout [String]) {
            guard let value, !value.isEmpty else { return }
            lines.append("  \(label): \(value)")
        }

        private static func appendFiles(_ files: [Xcode.File], title: String, to lines: inout [String]) {
            guard !files.isEmpty else { return }

            lines.append("  \(title):")
            for file in files.sorted(by: { $0.summaryPath < $1.summaryPath }) {
                lines.append("    - \(file.summaryPath)")
            }
        }

        private static func appendList(_ values: [String], title: String, to lines: inout [String]) {
            guard !values.isEmpty else { return }

            lines.append("  \(title):")
            for value in values.sorted() {
                lines.append("    - \(value)")
            }
        }
    }
}

extension Xcode.File {
    fileprivate var summaryPath: String {
        path ?? name ?? fullPath ?? label ?? "<unknown>"
    }
}

extension Xcode.PackageProductDependency {
    fileprivate var summaryText: String {
        if let package, !package.isEmpty {
            return "\(package) / \(productName)"
        }
        if let packagePath, !packagePath.isEmpty {
            return "\(packagePath) / \(productName)"
        }
        return productName
    }
}
