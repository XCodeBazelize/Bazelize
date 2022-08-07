//
//  LastKnownFileType.swift
//
//
//  Created by Yume on 2022/8/4.
//

import Foundation

/// `PBXFileReference.lastKnownFileType`
public enum LastKnownFileType: String {
    case h = "sourcecode.c.h"
    case objc = "sourcecode.c.objc"
    case objcpp = "sourcecode.cpp.objcpp"

    case strings = "text.plist.strings"
    case xcconfig = "text.xcconfig"
    case plist = "text.plist.xml"

    case asset = "folder.assetcatalog"

    case xib = "file.xib"

    case wrapper
}
