//
//  XCodeSPM.swift
//  
//
//  Created by Yume on 2022/7/29.
//

import Foundation

public protocol XCodeSPM {
    var url: String {get}
    var version: XCodeSPMVersion { get }
}

public enum XCodeSPMVersion: Encodable {
    case upToNextMajorVersion(String)
    case upToNextMinorVersion(String)
    case range(from: String, to: String)
    case exact(String)
    case branch(String)
    case revision(String)
}
