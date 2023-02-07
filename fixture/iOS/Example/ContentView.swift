//
//  ContentView.swift
//  Example
//
//  Created by Yume on 2023/1/7.
//

import Foundation
import SwiftUI

// MARK: - Frameworks
import Framework1
import Framework2
import Framework3

// MARK: - Static
#if canImport(Static)
import Static
#endif
#if canImport(Static2)
import Static2
#endif

// MARK: - Remote SPM
#if canImport(AnyCodable)
import AnyCodable
#endif

// MARK: - Local SPM deps
#if canImport(RxSwift)
import RxSwift
#endif

// MARK: - Local SPM
#if canImport(LocalTarget1)
import LocalTarget1
#endif
#if canImport(LocalTarget2)
import LocalTarget2
#endif
#if canImport(LocalTarget3)
import LocalTarget3
#endif

// MARK: - Imported Framework
import SVProgressHUDShare

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Assets")
                Image("bazel")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
            }.background(Color.brown)
            VStack {
                Text("Localize")
                Text("hello")
            }.background(Color.red)
            VStack {
                Text("Config")
                #if YDebug
                Text("Debug")
                #elseif YRelease
                Text("Release")
                #else
                Text("None")
                #endif
            }.background(Color.green)
            VStack {
                Text("Frameworks")
                Text(Framework1.test())
                Text(Framework2.test())
                Text(Framework3.test())
                #if canImport(Static)
                Text(Static.test())
                #endif
                #if canImport(Static2)
                Text(Static2.test())
                #endif
            }.background(Color.blue)
            VStack {
                Text("SPM")
                #if canImport(AnyCodable)
                Text(type: AnyCodable.self)
                #endif
                #if canImport(RxSwift)
                Text(type: MainScheduler.self)
                #endif
                #if canImport(LocalTarget1)
                Text(type: LocalTarget1.self)
                #endif
                #if canImport(LocalTarget2)
                Text(type: LocalTarget2.self)
                #endif
                #if canImport(LocalTarget3)
                Text(type: LocalTarget3.self)
                Text("\(LocalTarget3.test())")
                #endif
            }.background(Color.red)
            VStack {
                Text("Imported")
                Text(type: SVProgressHUD.self)
            }.background(Color.green)
        }
        .foregroundColor(Color.white)
        .padding()
    }
}

extension Text {
    init<T>(type: T.Type) {
        let text = "\(type)"
        self.init(text)
    }
}


// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
