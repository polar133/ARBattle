//
//  ARViewModel.swift
//  ARBattle
//

import Foundation
import Combine
import SwiftUI

enum ARAction {
    case start
    case reset
    case debug(enabled: Bool)
    case placeBlocks
    case restartBlocks
}

class ARViewModel: ObservableObject {

    var actions = PassthroughSubject<ARAction, Never>()

    @Published var isDebugEnabled: Bool = false

    @Published var hasStarted: Bool = false

    @Published var planeHasBeenFound: Bool = false

    @Published var blocksCanBePlaced: Bool = false

    @Published var blocksArePlaced: Bool = false

    @Published var noMeshDetected: Bool = false

    func showNoMeshDetectedMessage() {
        self.noMeshDetected = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.noMeshDetected = false
        }
    }
}
