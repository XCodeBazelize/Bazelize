//
//  File.swift
//  
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import XcodeProj

public protocol Target {
    var name: String { get }
    var srcs: String { get }
    var resources: String { get }
    var buildSettings: BuildSettings { get }
}

extension PBXNativeTarget: Target {
    public var srcFiles: [File] {
        guard let sourceBuildPhase = try? self.sourcesBuildPhase() else {
            return []
        }

        let files = sourceBuildPhase.files ?? []
        return files.compactMap(\.file)
    }
    
    public var srcs: String {
        return srcFiles.paths
    }
    
    public var resourceFiles: [File] {
        guard let phase = try? self.resourcesBuildPhase() else {
            return []
        }
        let files = phase.files ?? []
        return files.compactMap(\.file)
    }
    
    public var resources: String {
        return resourceFiles.paths
    }
    
    public var buildSettings: BuildSettings {
        .init(self)
    }
}
