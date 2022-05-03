//
//  File.swift
//  
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import Util

struct PodSpec: Codable, JSONParsable {
    let name: String
    let source: PodSpecSource
    
    /// new_pod_repository(
    ///   name = "PINOperation",
    ///   url = "https://github.com/pinterest/PINOperation/archive/1.2.1.zip",
    /// )
    var code: String {
        return """
        new_pod_repository(
          name = "\(name)",
          url = "\(source.url)",
        )
        """
    }
}

//  "source": {
//    "git": "https://github.com/yagiz/Bagel.git",
//    "tag": "1.4.0"
//  },
struct PodSpecSource: Codable {
    let git: String
    let tag: String
    
    /// https://github.com/yagiz/Bagel/archive/1.4.0.zip
    var url: String {
        let base = git.replacingOccurrences(of: ".git", with: "")
        return "\(base)/archive/\(tag).zip"
    }
}
