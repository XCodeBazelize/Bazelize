//
//  PodSpec.swift
//
//
//  Created by Yume on 2022/4/25.
//

import Foundation
import Util

// MARK: - PodSpec

struct PodSpec: Codable, JSONParsable, NewPodRepository {
    let name: String
    let source: PodSpecSource

    var url: String {
        source.url
    }
}

// MARK: - PodSpecSource

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
