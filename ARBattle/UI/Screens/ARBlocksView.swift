//
//  ARBlocksView.swift
//  ARBattle
//

import SwiftUI

struct ARBlocksView: View {

    @StateObject var viewModel = ARViewModel()

    var body: some View {
        ZStack {
            ARViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea()

                .overlay(alignment: .top) {
                    if viewModel.hasStarted {
                        HStack {
                            /// Debug Button
                            Button {
                                viewModel.actions.send(.debug(enabled: !$viewModel.isDebugEnabled.wrappedValue))
                            } label: {
                                Image(systemName: viewModel.isDebugEnabled ? "square.slash" : "squareshape.split.3x3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            Spacer()
                            /// Reset Button
                            Button {
                                viewModel.actions.send(.reset)
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                        }.padding(16)
                    }
                }
                .overlay(alignment: .center) {
                    if !viewModel.hasStarted {
                        /// Start Button
                        Button {
                            viewModel.actions.send(.start)
                        } label: {
                            Image(systemName: "play")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(25)
                        }
                    }
                    if viewModel.noMeshDetected {
                        Text("Surface too small to place cubes.")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                    }
                }
                .overlay(alignment: .bottom) {
                    if viewModel.hasStarted && viewModel.planeHasBeenFound {
                        if viewModel.blocksCanBePlaced {
                            if !viewModel.blocksArePlaced {
                                /// Place cubes Button
                                Button {
                                    viewModel.actions.send(.placeBlocks)
                                } label: {
                                    Text("Place Cubes")
                                        .padding(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10.0)
                                                .stroke(lineWidth: 1.0)
                                    )
                                }.padding(16)
                                    .shadow(color: .black, radius: 2, x: 0, y: 2)
                            } else {
                                /// Restart position of cubes Button
                                Button {
                                    viewModel.actions.send(.restartBlocks)
                                } label: {
                                    Text("Restart Cubes")
                                        .padding(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10.0)
                                                .stroke(lineWidth: 1.0)
                                        )
                                }.padding(16)
                                    .shadow(color: .black, radius: 2, x: 0, y: 2)

                            }
                        } else {
                            HStack {
                                Text("Scan more to get the surface.")
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                            }
                        }
                    }
                }
        }
    }
}

struct ARBlocksView_Previews: PreviewProvider {
    static var previews: some View {
        ARBlocksView()
    }
}
