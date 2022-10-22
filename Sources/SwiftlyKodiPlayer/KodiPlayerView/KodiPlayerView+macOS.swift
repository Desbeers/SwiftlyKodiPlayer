//
//  KodiPlayerView+macOS.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI

#if os(macOS)

extension KodiPlayerView {
    
    public struct ShowControllerView: ViewModifier {
        /// The Player model
        @EnvironmentObject var playerModel: KodiPlayerView.PlayerModel
        
        public func body(content: Content) -> some View {
            content
                .overlay(alignment: .bottom) {
                    if playerModel.showController {
                        KodiPlayerView.ControllerView()
                    }
                }
        }
    }
}
#endif
