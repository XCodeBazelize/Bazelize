//
//  PodfileLock.swift
//
//
//  Created by Yume on 2022/4/26.
//

import Foundation
import Util

// MARK: - PodfileLock

struct PodfileLock: Codable, YamlParsable {
    // MARK: Internal


    enum CodingKeys: String, CodingKey {
        case pods = "PODS"
        case externals = "EXTERNAL SOURCES"
        case checkouts = "CHECKOUT OPTIONS"
        case spec = "SPEC CHECKSUMS"
    }


    var repos: [NewPodRepository] {
        get async throws {
            try await withThrowingTaskGroup(of: NewPodRepository.self) { group -> [NewPodRepository] in
                for spec in specs {
                    group.addTask {
                        try await spec.repo(lock: self)
                    }
                }

                return try await group.all
            }.sorted { lhs, rhs in
                lhs.name < rhs.name
            }
        }
    }

    var repoCodes: [String] {
        get async throws {
            try await repos.map(\.code)
        }
    }

    // MARK: Private

    private let pods: [PodfileLock.Pod]
    private let externals: [String: ExternalSource]?
    private let checkouts: [String: CheckoutOption]?
    private let spec: [String: String]


    private var specs: [PodfileLock.Pod] {
        let set = Set(pods)
        return set.map { $0 }
    }
}

extension PodfileLock {
    /// //Vendor/__PACKAGE__:__TARGET__
    fileprivate struct Pod: Codable, Hashable, Equatable {
        // MARK: Lifecycle


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

        // MARK: Internal

        let package: String
        let target: String
        let tag: String


        static func == (lhs: Pod, rhs: Pod) -> Bool {
            lhs.package == rhs.package
        }


        func hash(into hasher: inout Hasher) {
            hasher.combine(package)
        }

        // MARK: Fileprivate


        fileprivate var isDefaultSubSpec: Bool {
            package == target
        }


        fileprivate func repo(lock: PodfileLock) async throws -> NewPodRepository {
            guard
                let external = lock.externals?[package],
                let checkout = lock.checkouts?[package]
            else {
                return try await podSpec
            }
            return try PodRepository(pod: self, external: external, checkout: checkout)
        }

        // MARK: Private


        /// pod spec cat Bagel --version=1.4.0
        private var podSpec: PodSpec {
            get async throws {
                let query = """
                    ^\(package)$
                    """
                .replacingOccurrences(of: "+", with: "\\+")
                .replacingOccurrences(of: ".", with: "\\.")
                let arg = "spec cat --regex \(query) --version=\(tag)"

                let data = try await Process.execute(
                    Env.pod,
//                    arguments: arg
                    arguments: "spec", "cat", "--regex", query, "--version=\(tag)")
                do {
                    return try PodSpec.parse(data)
                } catch {
                    print("""
                        Parse Podspec Fail
                        `\(Env.pod) spec cat --regex \(query) --version=\(tag)`
                        \(arg)
                        string: \(String(data: data, encoding: .utf8) ?? "")
                        \(error)

                        """)
                    throw error
                }
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

            let (package, target) = Util.parse(name: name)

            return .init(package: package, target: target, tag: tag)
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
        // MARK: Lifecycle


        fileprivate init(
            pod: PodfileLock.Pod,
            external: PodfileLock.ExternalSource,
            checkout: PodfileLock.CheckoutOption) throws
        {
            name = pod.package
            let base = external.git.replacingOccurrences(of: ".git", with: "")

            /// branch > tag > commit
            if let branch = external.branch {
                url = "\(base)/archive/\(branch).zip"
                return
            }

            if let tag = external.tag ?? checkout.tag {
                url = "\(base)/archive/\(tag).zip"
                return
            }

            if let commit = external.commit ?? checkout.commit {
                url = "\(base)/archive/\(commit).zip"
                return
            }

            #warning("todo error design")
            throw PodError.reason("""
                Parse Podfile.lock Error
                Can't find git at \(pod.package)
                """)
        }

        // MARK: Internal

        let name: String
        /// https://github.com/${organization,user}/${repo}/archive/${commit,branch,tag}.zip
        let url: String
    }
}
