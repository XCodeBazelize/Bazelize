//
//  File.swift
//  
//
//  Created by Yume on 2022/4/26.
//

import Foundation
import Util

struct PodfileLock: Codable, YamlParsable {
    private let pods: [PodfileLock.Pod]
    private let externals: [String: ExternalSource]
    private let checkouts: [String: CheckoutOption]
    
    enum CodingKeys: String, CodingKey {
        case pods = "PODS"
        case externals = "EXTERNAL SOURCES"
        case checkouts = "CHECKOUT OPTIONS"
    }
    
//    #warning("todo parse error")
//    var dependencies: [PodfileLock.Dependency] {
//        return []
////        pods.compactMap(\.dependency)
////            .filter { dep in
////                return dep.name != "ThirdParty"
////            }
//    }
    private var specs: [PodfileLock.Pod] {
        let set = Set(pods)
        return set.map { $0 }
    }
    
    var repos: [NewPodRepository] {
        get async throws {
            try await withThrowingTaskGroup(of: NewPodRepository.self) { group -> [NewPodRepository] in
                for spec in specs {
                    group.addTask {
                        return try await spec.aaaaa(lock: self)
                    }
                }

                var result: [NewPodRepository] = []
                for try await spec in group {
                    result.append(spec)
                }

                return result
            }.sorted(by: { lhs, rhs in
                return lhs.name < rhs.name
            })
        }
    }
    
    var repoCodes: [String] {
        get async throws {
            return try await self.repos.map(\.code)
        }
    }
}

extension PodfileLock {
    /// //Vendor/__PACKAGE__:__TARGET__
    fileprivate  struct Pod: Codable, Hashable, Equatable {
        let package: String
        let target: String
        let tag: String
        
        static func == (lhs: Pod, rhs: Pod) -> Bool {
            return lhs.package == rhs.package
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(package)
        }
        
        fileprivate var isDefaultSubSpec: Bool {
            return package == target
        }
        
        /// pod spec cat Bagel --version=1.4.0
        private func spec() async throws -> PodSpec {
            let data = try await Process.execute(
                Env.pod,
                arguments: "spec", "cat", package, "--version=\(tag)"
            )
            do {
                return try PodSpec.parse(data)
            } catch {
                print(package, tag, error)
                throw error
            }
        }
        
        fileprivate func aaaaa(lock: PodfileLock) async throws -> NewPodRepository {
            guard
                let external = lock.externals[package],
                let checkout = lock.checkouts[package]
            else {
                return try await spec()
            }
            return try PodRepository(pod: self, external: external, checkout: checkout)
        }
        
        init(package: String, target: String, tag: String) {
            self.package = package
            self.target = target
            self.tag = tag
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                let pod = try container.decode(String.self)
                self = try Self.parse(pod: pod)
            } catch {
                let podGraph = try container.decode([String: [String]].self)
                guard let pod = podGraph.keys.first else {
                    throw PodError.reason("""
                    Parse Podfile.lock fail
                    Pod: \(podGraph)
                    """)
                }
                self = try Self.parse(pod: pod)
            }
        }
        
        /// AFNetworking (4.0.1)
        /// AFNetworking/NSURLSession (4.0.1)
        private static func parse(pod: String) throws -> PodfileLock.Pod {
            let parts = pod.split(separator: " ").map(String.init)
            guard parts.count == 2 else {
                throw PodError.reason("""
                Parse Podfile.lock fail
                version
                Pod: \(pod)
                """)
            }

            let name = parts[0]
            let tag = parts[1]
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")

            let (package, target) = try Self.parse(name: name)
            
            return .init(package: package, target: target, tag: tag)
        }
        
        /// AFNetworking
        ///     AFNetworking, AFNetworking
        ///
        /// AFNetworking/NSURLSession
        ///     AFNetworking, NSURLSession
        private static func parse(name: String) throws -> (String, String) {
            let parts = name.split(separator: "/").map(String.init)
            switch parts.count {
            case 1:
                return (parts[0], parts[0])
            case 2:
                return (parts[0], parts[1])
            default:
                throw PodError.reason("""
                Parse Podfile.lock PODS["\(name)"] fail.
                """)
            }
        }
    }
}

/// EXTERNAL SOURCES:
extension PodfileLock {
    fileprivate struct ExternalSource: Codable {
        let git: String
        let tag: String?
        let commit: String?
        let branch: String?
        
        enum CodingKeys: String, CodingKey {
            case git = ":git"
            case tag = ":tag"
            case commit = ":commit"
            case branch = ":branch"
        }
    }
}


/// CHECKOUT OPTIONS:
extension PodfileLock {
    fileprivate struct CheckoutOption: Codable {
        let git: String
        let tag: String?
        let commit: String?
        
        enum CodingKeys: String, CodingKey {
            case git = ":git"
            case tag = ":tag"
            case commit = ":commit"
        }
    }
}

extension PodfileLock {
    fileprivate struct PodRepository: NewPodRepository {
        let name: String
        /// https://github.com/${organization,user}/${repo}/archive/${commit,branch,tag}.zip
        let url: String
        
        fileprivate init(pod: PodfileLock.Pod, external: PodfileLock.ExternalSource, checkout: PodfileLock.CheckoutOption) throws {
            self.name = pod.package
            let base = external.git.replacingOccurrences(of: ".git", with: "")

            /// branch > tag > commit
            if let branch = external.branch {
                self.url = "\(base)/archive/\(branch).zip"
                return
            }
            
            if let tag = external.tag ?? checkout.tag {
                self.url = "\(base)/archive/\(tag).zip"
                return
            }
            
            if let commit = external.commit ?? checkout.commit {
                self.url = "\(base)/archive/\(commit).zip"
                return
            }
            
            #warning("todo error")
            throw PodError.reason("""
            ParsePodfile.lock Error
            Can't find git at \(pod.package)
            """)
        }
    }
}
