//
//  Build+Builder.swift
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
            load(rule.code)
        }
        
        mutating
        func load(_ rule: RulesApple.Mac) {
            load(rule.code)
        }
        
        mutating
        func load(_ rule: RulesApple.TV) {
            load(rule.code)
        }
        
        mutating
        func load(_ rule: RulesApple.Watch) {
            load(rule.code)
        }
        
        mutating
        func load(_ rule: RulesSwift) {
            load(rule.code)
        }
        
        /// load function at top of the file.
        mutating
        func load(_ code: String) {
            codes.insert(code, at: 0)
        }
        
        /// append custom code.
        mutating
        func custom(_ code: String) {
            _code = code
        }
        
        func build() -> String {
            codes.joined(separator: "\n")
        }
    }
}
