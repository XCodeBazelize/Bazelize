//
//  Property+String.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

extension String {
    public func property(@LabelBuilder builder: () -> [LabelBuilder.Target]) -> Property {
        .init(self, builder: builder)
    }
}
