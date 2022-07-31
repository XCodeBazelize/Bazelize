//
//  XCodeProject.swift
//  
//
//  Created by Yume on 2022/7/25.
//

import Foundation
import PathKit

public protocol XCodeProject: AnyObject {

    /// WORKSPACE
    var workspacePath: Path { get }
    
    /// xxx.xcodeproj
    var projectPath: Path { get }
    
    /// relative path to local spm
    var localSPM: [String] { get }
    
    var spm: [XCodeSPM] { get}

    var targets: [XCodeTarget] { get }
    
    var config: [String: XCodeBuildSetting]? { get }
}
