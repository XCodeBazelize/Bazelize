//
//  File.swift
//  
//
//  Created by Yume on 2022/7/1.
//

import Foundation

struct Build {
    struct Builder {
        private var codes: [String] = []
        
        private var _code: String {
            get { "" }
            set { codes.append(newValue) }
        }
        
        mutating
        func load(_ rule: RulesApple.IOS) {
            custom(rule.code)
        }
        
        mutating
        func load(_ rule: RulesApple.Mac) {
            custom(rule.code)
        }
        
        mutating
        func load(_ rule: RulesApple.TV) {
            custom(rule.code)
        }
        
        mutating
        func load(_ rule: RulesApple.Watch) {
            custom(rule.code)
        }
        
        mutating
        func load(_ rule: RulesSwift) {
            custom(rule.code)
        }
        
        mutating
        func custom(_ code: String) {
            _code = code
        }
        
        func build() -> String {
            codes.joined(separator: "\n")
        }
    }
}
