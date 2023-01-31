//
//  ContentView.swift
//  Example
//
//  Created by Yume on 2023/1/7.
//

import Foundation
import Framework1
import Framework2
import Static
import SwiftUI
#if canImport(AnyCodable)
import AnyCodable
#endif
#if canImport(RxSwift)
import RxSwift
#endif

#if canImport(LocalTarget1)
import LocalTarget1
#endif
#if canImport(LocalTarget2)
import LocalTarget2
#endif

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
                .foregroundColor(Color.white)
            VStack {
                Text("Localize")
                Text("hello")
            }.background(Color.red)
                .foregroundColor(Color.white)
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
                .foregroundColor(Color.white)
            VStack {
                Text("Frameworks")
                Text("\(test1())")
                Text("\(test2())")
                Text("\(test3())")
                Text("\(test4())")
            }.background(Color.blue)
                .foregroundColor(Color.white)
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
            }.background(Color.red)
                .foregroundColor(Color.white)
        }
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
