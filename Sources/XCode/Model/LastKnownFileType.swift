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
    case c = "sourcecode.c.c"
    case objc = "sourcecode.c.objc"
    case hpp = "sourcecode.cpp.h"
    case cpp = "sourcecode.cpp.cpp"
    case objcpp = "sourcecode.cpp.objcpp"
    case swift = "sourcecode.swift"
    case metal = "sourcecode.metal"

    case strings = "text.plist.strings"
    case stringsdict = "text.plist.stringsdict"
    case plist = "text.plist.xml"
    case entitlements = "text.plist.entitlements"
    case xcconfig = "text.xcconfig"

    case asset = "folder.assetcatalog"

    case xib = "file.xib"
    case storyboard = "file.storyboard"

    case wrapper
}
