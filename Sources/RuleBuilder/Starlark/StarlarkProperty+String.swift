//
//  Property+String.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

extension String {
    public func property(@StarlarkBuilder builder: () -> Starlark) -> StarlarkProperty {
        .init(self, builder: builder)
    }
}
