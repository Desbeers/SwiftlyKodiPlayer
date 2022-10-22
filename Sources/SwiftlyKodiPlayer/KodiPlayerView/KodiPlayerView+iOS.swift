//
//  KodiPlayerView+iOS.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI

#if os(iOS)

extension KodiPlayerView {
    
    public struct ShowControllerView: ViewModifier {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerView.PlayerModel
        /// Dismiss the window
        @Environment(\.dismiss) private var dismiss
        
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
                        PlayerView.ControllerView()
                    }
                }
        }
    }
}
#endif
