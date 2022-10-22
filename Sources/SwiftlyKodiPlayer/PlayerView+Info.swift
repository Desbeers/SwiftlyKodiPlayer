//
//  PlayerView+Info.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import SwiftlyKodiAPI
import KSPlayer
import Foundation

extension PlayerView {
    
    /// The Info View for the Controller
    struct InfoView: View {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerModel
        /// The Coordinator model
        @EnvironmentObject var config: KSVideoPlayer.Coordinator
        /// The body of the View
        public var body: some View {
            
            HStack {
                playerModel.metaData.artwork
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(PlayerModel.controllerHeight / 30)
                VStack(alignment: .leading) {
                    Text(playerModel.metaData.title)
                        .font(.headline)
                    Text(playerModel.metaData.description)
                    Spacer()
                    Slider(value: Binding {
                        Double(playerModel.currentTime)
                    } set: { newValue, _ in
                        playerModel.currentTime = Int(newValue)
                    }, in: 0 ... Double(playerModel.totalTime)) { onEditingChanged in
                        if onEditingChanged {
                            config.isPlay = false
                        } else {
                            config.seek(time: TimeInterval(playerModel.currentTime))
                        }
                    }
                    .frame(maxHeight: 20)
                    .tint(.white)
                    HStack {
                        Text(playerModel.currentTime.toString(for: .minOrHour)).font(.caption2.monospacedDigit())
                        Spacer()
                        Text("-" + (playerModel.totalTime - playerModel.currentTime).toString(for: .minOrHour)).font(.caption2.monospacedDigit())
                    }
                }
            }
        }
    }
}
