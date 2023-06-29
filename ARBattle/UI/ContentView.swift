//
//  ContentView.swift
//  ARBattle
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ARBlocksView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
