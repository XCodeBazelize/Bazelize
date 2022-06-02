//
//  NewPodRepository.swift
//  
//
//  Created by Yume on 2022/5/11.
//

import Foundation

/// https://github.com/${organization,user}/${repo}/archive/${commit,branch,tag}.zip
///
/// new_pod_repository(
///   name = "PINOperation",
///   url = "https://github.com/pinterest/PINOperation/archive/1.2.1.zip",
/// )
protocol NewPodRepository {
    var name: String { get }
    var url: String { get }
    
    var code: String { get }
}

extension NewPodRepository {
    var code: String {
        return """
        new_pod_repository(
          name = "\(name)",
          url = "\(url)",
        )
        """
    }
}
