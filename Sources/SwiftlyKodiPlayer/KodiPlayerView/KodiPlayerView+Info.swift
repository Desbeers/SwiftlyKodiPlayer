//
//  KodiPlayerView+Info.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import SwiftlyKodiAPI
import KSPlayer
import Foundation

extension KodiPlayerView {
    
    /// The Info View for the Controller
    struct InfoView: View {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerModel
        /// The Coordinator model
        @EnvironmentObject var config: KSVideoPlayer.Coordinator
        /// The current time for the slider
        @State private var sliderTime: Double = 0
        /// The body of the View
        public var body: some View {
            
            HStack {
                playerModel.metaData.artwork
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                VStack(alignment: .leading) {
                    Text(playerModel.metaData.title)
                        .font(.headline)
                    Text(playerModel.metaData.description)
                    Spacer()
                    Slider(value: $sliderTime,
                           in: 0 ... Double(playerModel.totalTime),
                           onEditingChanged: { onEditingChanged in
                        if !onEditingChanged {
                            config.seek(time: TimeInterval(sliderTime))
                        }
                    })
                    .frame(maxHeight: 20)
                    .tint(.white)
                    HStack {
                        Text(playerModel.currentTime.toString(for: .minOrHour)).font(.caption2.monospacedDigit())
                        Spacer()
                        Text("-" + (playerModel.totalTime - playerModel.currentTime).toString(for: .minOrHour)).font(.caption2.monospacedDigit())
                    }
                }
            }
            .animation(.default, value: sliderTime)
            .task {
                sliderTime = Double(playerModel.currentTime)
            }
            .onChange(of: playerModel.currentTime) { time in
                /// Update the slider only when we are playing
                if playerModel.state != .buffering {
                    sliderTime = Double(time)
                }
            }
        }
    }
}
