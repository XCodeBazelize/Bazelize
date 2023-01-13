//
//  ContentView.swift
//  Example
//
//  Created by Yume on 2023/1/7.
//

import Framework1
import Framework2
import Static
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        VStack {
            Image("bazel")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("hello")
            #if YDebug
            Text("Debug")
            #elseif YRelease
            Text("Release")
            #else
            Text("None")
            #endif
            Text("\(test1())")
            Text("\(test2())")
            Text("\(test3())")
            Text("\(test4())")
        }
        .padding()
    }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
