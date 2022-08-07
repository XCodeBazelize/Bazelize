//
//  Property+String.swift
//  
//
//  Created by Yume on 2022/8/2.
//

import Foundation

public extension String {
    func property(@LabelBuilder builder: () -> [LabelBuilder.Target]) -> Property {
        return .init(self, builder: builder)
    }
}
