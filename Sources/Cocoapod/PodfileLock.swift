//
//  File.swift
//  
//
//  Created by Yume on 2022/4/26.
//

import Foundation
import Util

struct PodfileLock: Codable, YamlParsable {
    private let PODS: [PodfileLock.Pod]
    
    #warning("todo parse error")
    var dependencies: [PodfileLock.Dependency] {
        return PODS.compactMap(\.dependency)
            .filter { dep in
                return dep.name != "ThirdParty"
            }
    }
    
    var specs: [PodSpec] {
        get async throws {
            return try await withThrowingTaskGroup(of: PodSpec.self) { group -> [PodSpec] in
                for dependency in dependencies {
                    group.addTask {
                        return try await dependency.process()
                    }
                }
                
                var result: [PodSpec] = []
                for try await spec in group {
                    result.append(spec)
                }
                
                return result
            }
        }
    }
}

extension PodfileLock {
    private enum Pod: Codable {
        /// - CocoaAsyncSocket (7.6.5)
        case single(String)
        /// - Bagel (1.4.0):
        ///   - CocoaAsyncSocket
        case sub([String: [String]])
        
        var dependency: Dependency? {
            switch self {
            case .single(let pod):
                return Dependency.parse(pod: pod)
            case .sub(let sub):
                guard let pod = sub.first?.key else {return nil}
                return Dependency.parse(pod: pod)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                self = try .single(container.decode(String.self))
            } catch {
                self = try .sub(container.decode([String: [String]].self))
            }
        }
    }
}

extension PodfileLock {
    struct Dependency {
        let name: String
        let tag: String
        
        private var isSubSpec: Bool {
            return name.contains("/")
        }
        
        static func parse(pod: String) -> Dependency? {
            let strs = pod.split(separator: " ")
            guard strs.count == 2 else { return nil }
            
            let name = String(strs[0])
            let tag = String(strs[1]
                                .replacingOccurrences(of: "(", with: "")
                                .replacingOccurrences(of: ")", with: ""))
            
            let dep = Dependency(name: name, tag: tag)
            #warning("TODO: don't skip sub spec")
            guard !dep.isSubSpec else { return nil }
            return dep
        }
        
        /// pod spec cat Bagel --version=1.4.0
        fileprivate func process() async throws -> PodSpec {
            let data = try await Process.execute(
                Env.pod,
                arguments: "spec", "cat", name, "--version=\(tag)"
            )
            do {
                return try PodSpec.parse(data)
            } catch {
                print(name, tag, error)
                throw error
            }
        }
    }
}
