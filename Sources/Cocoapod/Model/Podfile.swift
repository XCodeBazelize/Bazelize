//
//  Podfile.swift
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
    
    var depsCode: String {
        return dependencies?
            .sorted { lhs, rhs in
                lhs.code < rhs.code
            }
            .map(\.code)
            .joined(separator: "\n") ?? ""
    }
}

fileprivate struct PodDependency: Codable {
    let package: String
    let target: String
    
    /// //Vendor/__PACKAGE__:__TARGET__
    ///
    /// subpsec `Core` in `PINCache`
    /// //Vendor/PINCache:Core
    ///
    /// "//Vendor/RxSwift:RxSwift",
    var code: String {
        return """
        "//Vendor/\(package):\(target)",
        """
    }
    
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
}
