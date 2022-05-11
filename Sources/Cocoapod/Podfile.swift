//
//  File.swift
//  
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import AnyCodable
import Util
import PathKit

struct Podfile: Codable, JSONParsable {
    fileprivate let target_definitions: [PodDefinition]
    fileprivate var flatTarget: [PodChildren] {
        return target_definitions.flatMap(\.flatTarget)
    }
    
    subscript(targetName: String) -> String {
        return self[target: targetName]?.depsCode ?? ""
    }
    
    fileprivate subscript(target targetName: String) -> PodChildren? {
        return flatTarget.first { _target in
            return _target.name == targetName
        }
    }
    
    static func process(_ path: Path) async throws -> Podfile {
        /// pod ipc podfile-json Podfile
        let data = try await Process.execute(
            Env.pod,
            arguments: "ipc", "podfile-json", path.string
        )
        
        return try Podfile.parse(data)
    }
}

fileprivate struct PodDefinition: Codable {
    fileprivate let children: [PodChildren]
    fileprivate var flatTarget: [PodChildren] {
        return children.flatMap(\.flatTarget)
    }
}

fileprivate struct PodChildren: Codable {
    /// Target
    fileprivate let name: String
    fileprivate let dependencies: [PodDependency]?
//    "configuration_pod_whitelist": {
//                "Debug": [
//                  "Peek",
//                  "Bagel"
//                ]
//              },
//    let configuration_pod_whitelist
    private let children: [PodChildren]?
    
    fileprivate var flatTarget: [PodChildren] {
        if let child = self.children {
            return [self] + child.flatMap(\.flatTarget)
        } else {
            return [self]
        }
    }
    
    fileprivate var deps: [String] {
        return dependencies?.compactMap(\.name) ?? []
    }
    
    /// //Vendor/__PACKAGE__:__TARGET__
    ///
    /// subpsec `Core` in `PINCache`
    /// //Vendor/PINCache:Core
    ///
    /// "//Vendor/RxSwift:RxSwift",
    var depsCode: String {
        return deps.map { dep in
            return """
                    "//Vendor/\(dep):\(dep)",
            """
        }.joined(separator: "\n")
    }
}

fileprivate enum PodDependency: Codable {
    /// "TLPhotoPicker",
    case normal(String)
    /// {
    ///   "CocoaMQTT": [
    ///     "~> 1.3.0-rc.1"
    ///   ]
    /// },
    case version([String: [String]])
    case any(AnyCodable)
    
    var name: String? {
        switch self {
        case .normal(let name):
            return name
        case .version(let ver):
            return ver.first?.key
        default:
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = try .normal(container.decode(String.self))
            return
        } catch {
            do {
                self = try .version(container.decode([String: [String]].self))
            } catch {
                self = try .any(container.decode(AnyCodable.self))
            }
        }
    }
}
