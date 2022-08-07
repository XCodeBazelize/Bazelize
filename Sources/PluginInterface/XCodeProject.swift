//
//  XCodeProject.swift
//
//
//  Created by Yume on 2022/7/25.
//

import Foundation
import PathKit

// MARK: - XCodeProject

public protocol XCodeProject: AnyObject {
    /// WORKSPACE
    var workspacePath: Path { get }

    /// xxx.xcodeproj
    var projectPath: Path { get }

    /// relative path to local spm
    var localSPM: [String] { get }

    var spm: [XCodeSPM] { get }

    var targets: [XCodeTarget] { get }

    var config: [String: XCodeBuildSetting]? { get }

    func transformToLabel(_ path: String?) -> String?
}

extension XCodeProject {
    // MARK: Public


    public func transformToLabel(_ relativePath: String?) -> String? {
        /// DEF/Base.lproj/LaunchScreen.storyboard
        guard let path = relativePath else { return nil }

        let commentedLabel = """
            "# \(path)",
            """
        guard let _package = path.split(separator: "/").first else {
            return commentedLabel
        }
        /// DEF
        let package = String(_package)
        /// Base.lproj/LaunchScreen.storyboard
        guard let restPath = path.delete(prefix: package + "/") else {
            return commentedLabel
        }

        if check(package) {
            return """
                "//\(package):\(restPath)",
                """
        } else {
            return """
                "//:\(package)/\(restPath)",
                """
        }
    }

    // MARK: Private

    private typealias Package = String

    private func check(_ package: Package) -> Bool {
        targets.map(\.name).contains(package)
    }
}

extension String {
    fileprivate func delete(prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
