//
//  PlayerView+Controller.swift
//  Kodio
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import SwiftlyKodiAPI
import KSPlayer

extension PlayerView {
    
    
    /// The Controller View for the player
    struct ControllerView: View {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerModel
        
        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
        /// The body of the View
        public var body: some View {
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
                        TimeView()
                    case .audio:
                        AudioSettingsView()
                    case .subtitles:
                        SubtitleSettingsView()
                    }
                }
                .frame(height: 300)
                .padding(.horizontal)
            }
            
            
            .padding()
            .background(.thinMaterial)
            .cornerRadius(20)
            .padding()
            .animation(.default, value: playerModel.selectedTab)
#if os(tvOS)
            .onExitCommand {
                playerModel.showController = false
            }
            .onPlayPauseCommand {
                print("Toggle Play")
                config.isPlay.toggle()
            }
#endif
        }
    }
    
    
    
    //    /// The Controller View for the player
    //    struct ControllerView: View {
    //        /// The Player model
    //        @EnvironmentObject var playerModel: PlayerModel
    //
    //        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
    //        /// The body of the View
    //        public var body: some View {
    //                HStack {
    //                    playerModel.metaData.artwork
    //                        .resizable()
    //                        .aspectRatio(contentMode: .fit)
    //                        .frame(height: 200)
    //                        .cornerRadius(6)
    //
    //                    TabView(selection: $playerModel.selectedTab) {
    //                        TimeView()
    //                            .tabItem {
    //                                Label("Info", systemImage: "info.circle.fill")
    //                            }
    //                            .tag(PlayerModel.Tabs.info)
    //                        AudioSettingsView()
    //                            .tabItem {
    //                                Label("Audio", systemImage: "waveform")
    //                            }
    //                            .tag(PlayerModel.Tabs.audio)
    //                        SubtitleSettingsView()
    //                            .tabItem {
    //                                Label("Subtitles", systemImage: "pencil.line")
    //                            }
    //                            .tag(PlayerModel.Tabs.subtitles)
    //                    }
    //                    .frame(maxHeight: 360)
    //                //}
    //            }
    //            .padding()
    //            .background(.thickMaterial)
    //            #if os(tvOS)
    //            .onExitCommand {
    //                playerModel.showController = false
    //            }
    //            .onPlayPauseCommand {
    //                print("Toggle Play")
    //                config.isPlay.toggle()
    //            }
    //            #endif
    //        }
    //    }
    
    /// The Time View for the PLayer
    struct TimeView: View {
        /// The Player model
        @EnvironmentObject var playerModel: PlayerModel
        /// The Coordinator model
        @EnvironmentObject var config: KSVideoPlayer.Coordinator
        
        //@Environment(\.isFocused) var isFocused: Bool
        /// The body of the View
        public var body: some View {
            
            HStack {
                playerModel.metaData.artwork
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                //.frame(height: 200)
                    .cornerRadius(14)
                VStack(alignment: .leading) {
                    Text(playerModel.metaData.title)
                        .font(.headline)
                    Text(playerModel.metaData.description)
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
                    //.focusSection()
                    //.background(isFocused ? .green : .blue)
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
