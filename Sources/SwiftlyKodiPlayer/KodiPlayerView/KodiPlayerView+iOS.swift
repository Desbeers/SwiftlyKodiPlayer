//
//  KodiPlayerView+iOS.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import KSPlayer

#if os(iOS)

extension KodiPlayerView {
    
    // MARK: Gestures
    
    /// Gestures for the macOS player
    public struct PlayerGestures: ViewModifier {
        /// The Coordinator model
        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
        /// The Player model
        @EnvironmentObject var playerModel: KodiPlayerView.PlayerModel
        /// Dismiss the window
        @Environment(\.dismiss) private var dismiss
        /// The body of the ViewModifier
        public func body(content: Content) -> some View {
            content
                .onTapGesture(count: 2) {
                    config.isPlay.toggle()
                }
                .onTapGesture(count: 1) {
                    playerModel.showController.toggle()
                }
                .gesture(
                    DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                        .onEnded { value in
                            print(value.translation)
                            switch(value.translation.width, value.translation.height) {
                            case (...0, -30...30):
                                print("left swipe")
                            case (0..., -30...30):
                                print("right swipe")
                            case (-100...100, ...0):
                                print("up swipe")
                            case (-100...100, 0...):
                                print("down swipe")
                                dismiss()
                            default:  print("no clue")
                            }
                        }
                )
        }
    }
    
    // MARK: Controller
    
    /// Show the controller view
    public struct ShowControllerView: ViewModifier {
        /// The Player model
        @EnvironmentObject var playerModel: KodiPlayerView.PlayerModel
        /// Dismiss the window
        @Environment(\.dismiss) private var dismiss
        /// The body of the ViewModifier
        public func body(content: Content) -> some View {
            content
                .overlay(alignment: .topLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark").imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .opacity(playerModel.showController ? 1 : 0)
                    .padding()
                }
                .overlay(alignment: .bottom) {
                    if playerModel.showController {
                        //Spacer()
                        KodiPlayerView.ControllerView()
                    }
                }
        }
    }
}

#endif
