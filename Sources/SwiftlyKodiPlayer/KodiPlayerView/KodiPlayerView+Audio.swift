//
//  KodiPlayerView+Audio.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import SwiftlyKodiAPI
import KSPlayer

extension KodiPlayerView {
    
    /// Audio Settings View
    struct AudioSettingsView: View {
        /// The Coordinator model
        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
        /// The selected audio track
        @State var selectedAudioTrack: MediaPlayerTrack?
        /// The body of the View
        var body: some View {
            ScrollView {
                VStack {
                    Button(action: {
                        config.selectedAudioTrack = nil
                        selectedAudioTrack = nil
                    }, label: {
                        Label(title: {
                            Text("None")
                                .frame(width: 400, alignment: .leading)
                        }, icon: {
                            Image(systemName: "checkmark")
                                .opacity(selectedAudioTrack == nil ? 1 : 0)
                        })
                    })
                    ForEach(config.audioTracks, id: \.trackID) { track in
                        Button(action: {
                            config.selectedAudioTrack = config.audioTracks.first { $0.trackID == track.trackID }
                            selectedAudioTrack = config.selectedAudioTrack
                        }, label: {
                            Label(title: {
                                audioLabel(track: track)
                                    .frame(width: 400, alignment: .leading)
                            }, icon: {
                                Image(systemName: "checkmark")
                                    .opacity(selectedAudioTrack?.trackID == track.trackID ? 1 : 0)
                            })
                        })
                    }
                }
                .padding(.horizontal, 100)
            }
            .buttonStyle(.plain)
            .task {
                config.selectedAudioTrack = (config.playerLayer?.player.isMuted ?? false) ? nil : config.audioTracks.first { $0.isEnabled }
                selectedAudioTrack = config.selectedAudioTrack
            }
        }
        
        private func audioLabel(track: MediaPlayerTrack) -> some View {
            let items = track.description.split(separator: ",")
            
            var text = Locale.current.localizedString(forLanguageCode: track.language ?? "Und") ?? ""
            
            text += " ∙"
            text += items[1].description
            text += " ∙"
            text += items[4].description
            
            return Text(text)
        }
    }
}
