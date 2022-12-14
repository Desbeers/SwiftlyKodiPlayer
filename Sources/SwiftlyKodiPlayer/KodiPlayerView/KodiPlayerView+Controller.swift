//
//  KodiPlayerView+Controller.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import SwiftlyKodiAPI
import KSPlayer

extension KodiPlayerView {

    /// The Controller View for the player
    struct ControllerView: View {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerModel
        /// The Coordinator model
        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
        /// The body of the View
        public var body: some View {
            GeometryReader { geometry in
                VStack {
                    Picker("Fields", selection: $playerModel.selectedTab) {
                        Text("Info")
                            .tag(PlayerModel.Tabs.info)
                        Text("Audio")
                            .tag(PlayerModel.Tabs.audio)
                        Text("Subtitles")
                            .tag(PlayerModel.Tabs.subtitles)
                    }
                    .padding(.horizontal)
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Group {
                        switch playerModel.selectedTab {
                            
                        case .info:
                            InfoView()
                        case .audio:
                            AudioSettingsView()
                        case .subtitles:
                            SubtitleSettingsView()
                        }
                    }
                    .transition(.move(edge: .bottom))
//                    .frame(height: PlayerModel.controllerHeight)
                    .padding(.horizontal)
                }
                
                
                .padding()
                .background(.thinMaterial)
                .cornerRadius(20)
                .padding()
                .animation(.default, value: playerModel.selectedTab)
                /// Actions when the View is ready
                    .task {
                        /// Store the View size
                        playerModel.controllerSize = geometry.size
                    }
            }
        }
    }
}
