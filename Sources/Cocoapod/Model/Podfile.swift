//
//  Podfile.swift
//
//
//  Created by Yume on 2022/4/25.
//

import AnyCodable
import Foundation
import PathKit
import Util

// MARK: - Podfile

struct Podfile: Codable, JSONParsable {
    // MARK: Internal

    static func process(_ path: Path) async throws -> Podfile {
        /// pod ipc podfile-json Podfile
        let data = try await Process.execute(
            Env.pod,
            arguments: "ipc", "podfile-json", path.string)

        return try Podfile.parse(data)
    }


    subscript(targetName: String) -> [String] {
        self[target: targetName]?.depsCode ?? []
    }

    // MARK: Fileprivate

    fileprivate let target_definitions: [PodDefinition]

    fileprivate var flatTarget: [PodChildren] {
        target_definitions.flatMap(\.flatTarget)
    }


    fileprivate subscript(target targetName: String) -> PodChildren? {
        flatTarget.first { _target in
            _target.name == targetName
        }
    }
}

// MARK: - PodDefinition

private struct PodDefinition: Codable {
    fileprivate let children: [PodChildren]
    fileprivate var flatTarget: [PodChildren] {
        children.flatMap(\.flatTarget)
    }
}

// MARK: - PodChildren

private struct PodChildren: Codable {
    // MARK: Internal

    var depsCode: [String] {
        dependencies?
            .sorted { lhs, rhs in
                lhs.code < rhs.code
            }
            .map(\.code) ?? []
    }

    // MARK: Fileprivate

    /// Target
    fileprivate let name: String
    fileprivate let dependencies: [PodDependency]?


    fileprivate var flatTarget: [PodChildren] {
        if let child = children {
            return [self] + child.flatMap(\.flatTarget)
        } else {
            return [self]
        }
    }

    // MARK: Private

//    "configuration_pod_whitelist": {
//                "Debug": [
//                  "Peek",
//                  "Bagel"
//                ]
//              },
//    let configuration_pod_whitelist
    private let children: [PodChildren]?
}

// MARK: - PodDependency

private struct PodDependency: Codable {
    // MARK: Lifecycle

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let name = try container.decode(String.self)
            (package, target) = Util.parse(name: name)
            return
        } catch {
            let podGraph = try container.decode([String: AnyCodable].self)
            guard let name = podGraph.keys.first else {
                throw PodError.reason("""
                Parse Podfile fail
                Pod: \(podGraph)
                """)
            }

            (package, target) = Util.parse(name: name)
            return
        }
    }

    // MARK: Internal

    let package: String
    let target: String


    /// //Vendor/__PACKAGE__:__TARGET__
    ///
    /// subpsec `Core` in `PINCache`
    /// //Vendor/PINCache:Core
    ///
    /// "//Vendor/RxSwift:RxSwift",
    var code: String {
        """
        "//Vendor/\(package):\(target)",
        """
    }
}
