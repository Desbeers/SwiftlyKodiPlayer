//
//  PlayerView+Subtitles.swift
//  Kodio
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import SwiftlyKodiAPI
import KSPlayer

extension PlayerView {
    
    struct SubtitleView: View {
        @EnvironmentObject var playerModel: PlayerModel
        var body: some View {
            if let text = playerModel.subtitleText {
                Text(AttributedString(text))
                    .multilineTextAlignment(.center)
                    .font(playerModel.subtitleFont)
                    .foregroundColor(.white).shadow(color: .black.opacity(0.9), radius: 2, x: 2, y: 2)
                    .padding(.bottom, playerModel.subtitleOffset)
            }
        }
    }
    
    /// Subtitle Settings View
    struct SubtitleSettingsView: View {
        /// The Coordinator model
        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
        /// The body of the View
        var body: some View {
            VStack(spacing: 0) {
                Button(action: {
                    config.selectedSubtitleTrack = nil
                }, label: {
                    Label(title: {
                        Text("None")
                            .frame(width: 300, alignment: .leading)
                    }, icon: {
                        Image(systemName: "checkmark")
                            .opacity(config.selectedSubtitleTrack == nil ? 1 : 0)
                    })
                })
                ForEach(config.subtitleTracks, id: \.trackID) { track in
                    Button(action: {
                        config.selectedSubtitleTrack = config.subtitleTracks.first { $0.trackID == track.trackID }
                    }, label: {
                        Label(title: {
                            Text(Locale.current.localizedString(forLanguageCode: track.name) ?? track.name)
                                .frame(width: 300, alignment: .leading)
                        }, icon: {
                            Image(systemName: "checkmark")
                                .opacity(config.selectedSubtitleTrack?.trackID == track.trackID ? 1 : 0)
                        })
                    })
                }
            }
            .buttonStyle(.plain)
        }
    }
}

extension PlayerView.PlayerModel {
    
    /// Calculate the subtitle offset
    func setSubtitleOffset() {
        
        let playerSize = CGSize(width: 1920, height: 1080)
        
        let videoRatio = (naturalSize.width / naturalSize.height)
        let viewRatio = (playerSize.width / playerSize.height)
        var offset: Double = showController ? PlayerView.PlayerModel.controllerHeight : 20
        if viewRatio < videoRatio {
            /// Bars on top
            let videoHeight = playerSize.width / videoRatio
            offset = ((playerSize.height - videoHeight) / 2.0) + offset
        }
        subtitleOffset = offset
    }
}
