//
//  Codegen+StaticFramework.swift
//
//
//  Created by Yume on 2022/5/4.
//

import BazelRules
import Foundation
import Starlark

extension Target {
    /// A framework target that links statically: `MACH_O_TYPE = staticlib`, or the
    /// product type Xcode gives a target created as a static framework.
    ///
    /// Nothing loads such a framework at runtime — its objects end up inside
    /// whatever links it — so there is no bundle to build. The label a dependent
    /// names stays valid by pointing at the library the target already generates.
    var isStaticFramework: Bool {
        if productType == "com.apple.product-type.framework.static" { return true }
        guard productType == "com.apple.product-type.framework" else { return false }
        return prefer(\.machOType) == "staticlib"
    }

    func generateStaticFrameworkCode(_ builder: CodeBuilder, _: Kit) {
        builder.call(
            Rules.Builtin.Call.alias(
                name: name,
                actual: .named("\(name)_library"),
                visibility: .public))
    }
}
