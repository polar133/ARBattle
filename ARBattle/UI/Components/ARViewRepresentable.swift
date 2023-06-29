//
//  ARViewRepresentable.swift
//  ARBattle
//

import SwiftUI
import Combine

struct ARViewRepresentable: UIViewRepresentable {

    @ObservedObject var viewModel: ARViewModel

    func makeUIView(context: Context) -> BattleARView {
        let arView = BattleARView(viewModel: viewModel)
        return arView
    }

    func updateUIView(_ uiView: BattleARView, context: Context) {
    }

}
