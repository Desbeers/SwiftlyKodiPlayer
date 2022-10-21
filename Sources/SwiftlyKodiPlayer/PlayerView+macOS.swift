//
//  PlayerView+macOS.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI

#if os(macOS)

extension PlayerView {
    
    public struct ShowControllerView: ViewModifier {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerView.PlayerModel
        
        public func body(content: Content) -> some View {
            content
                .overlay(alignment: .bottom) {
                    if playerModel.showController {
                        PlayerView.ControllerView()
                    }
                }
        }
    }
}
#endif
