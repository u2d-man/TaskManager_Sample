//
//  ContentView.swift
//  TaskManager
//
//  Created by kazunari_ueeda on 2022/01/10.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Home(calendar: Calendar(identifier: .gregorian))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
