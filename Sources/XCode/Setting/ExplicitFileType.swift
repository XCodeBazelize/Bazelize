//
//  ExplicitFileType.swift
//
//
//  Created by Yume on 2023/1/18.
//

import Foundation

/// `PBXFileReference.explicitFileType`
public enum ExplicitFileType: String, Equatable {
    /// libXXX.a
    case archive = "archive.ar"

    case framework = "wrapper.framework"
}
