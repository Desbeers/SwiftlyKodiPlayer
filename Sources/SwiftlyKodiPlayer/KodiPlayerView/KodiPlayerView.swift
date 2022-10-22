//
//  KodiPlayerView.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

//import AVFoundation
//import AVKit
import SwiftUI
import KSPlayer
import SwiftlyKodiAPI

/// The Kodi Player View
public struct KodiPlayerView: View {
    /// The item we want to play
    let item: any KodiItem
    /// The Player model
    @StateObject var playerModel: PlayerModel
    /// The state of the player
    @State private var state: KSPlayerState = .prepareToPlay
    /// Dismiss the window
    @Environment(\.dismiss) private var dismiss
    /// The actual player
    let player: KSVideoPlayer
    /// Init the player with the video
    public init(item: any KodiItem, resume: Bool = false) {
        /// Init the player
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.isAutoPlay = true
        let url = URL(string: Files.getFullPath(file: item.file, type: .file))!
        let options = KSOptions()
        if resume {
            options.startPlayTime = item.resume.position
        }
        player = KSVideoPlayer(url: url, options: options)
        _playerModel = StateObject(wrappedValue: PlayerModel(video: item))
        self.item = item
    }
    /// The body of the View
    public var body: some View {
        GeometryReader { geometry in
            player
                .onPlay { current, total in
                    playerModel.currentTime = Int(current)
                    playerModel.totalTime = Int(max(max(0, total), current))
                    if let subtitle = playerModel.selectedSubtitle {
                        if let part = subtitle.search(for: current) {
                            playerModel.subtitleTime = part.end
                            playerModel.subtitleText = part.text
                        } else {
                            if current > playerModel.subtitleTime {
                                playerModel.subtitleText = nil
                            }
                        }
                    } else {
                        playerModel.subtitleText = nil
                    }
                }
                .onStateChanged { layer, status in
                    state = status
                    playerModel.state = status
                    switch playerModel.state {
                    case .prepareToPlay:
                        break
                    case .readyToPlay:
                        /// Select the first subtitle
                        if let subtitle = player.coordinator.subtitleTracks.first {
                            player.coordinator.selectedSubtitleTrack = subtitle
                        }
                        /// Select the last audio track; that should be the highest quality
                        if let audio = player.coordinator.audioTracks.last {
                            player.coordinator.selectedAudioTrack = audio
                        }
                        /// Store the natural sie of the video; used to calculate subtitle offset
                        playerModel.naturalSize = layer.player.naturalSize
                    case .buffering:
                        break
                    case .bufferFinished:
                        break
//                        if playerModel.showController {
//                            Task {
//                                try await Task.sleep(nanoseconds: 1_000_000_000)
//                                playerModel.showController = false
//                            }
//                        }
                        //playerModel.naturalSize = layer.player.naturalSize
                    case .paused:
                        //playerModel.showController = true
                        break
                    case .playedToTheEnd:
                        /// Close the view
                        dismiss()
                    case .error:
                        break
                    }
                }
            /// Keep an eye on the subtitles
                .onReceive(player.coordinator.$selectedSubtitleTrack) { track in
                    guard let subtitle = track as? SubtitleInfo else {
                        playerModel.selectedSubtitle = nil
                        return
                    }
                    subtitle.enableSubtitle { result in
                        playerModel.selectedSubtitle = try? result.get()
                    }
                }
            /// Overlay the subtitles
                .overlay(alignment: .bottom) {
                    SubtitleView()
                }
            /// Overlay the state
                .overlay(alignment: .center) {
                    switch state {
                    case .prepareToPlay, .buffering:
                        ProgressView()
                        /// - Note: 'tint' does not work on macOS to set the color
                            .colorInvert() /// make the spinner a semi-opaque white
                            .brightness(1) /// ramp up the brightness
                    case .paused:
                        VStack {
                            Image(systemName: "pause.fill")
                                .font(.largeTitle)
                            Text(remainingTime(duration: (playerModel.totalTime - playerModel.currentTime)))
                                .padding()
                        }
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(20)
                    default:
                        EmptyView()
                    }
                }
            /// Add the controller view
                .controller()
            /// Add platform specific gestures
                .gestures()
            /// Actions when the View is ready
                .task {
                    /// Store the View size
                    playerModel.playerSize = geometry.size
                    /// Load the poster art
                    await playerModel.getArtwork()
                }
            /// Keep an eye on the window side; I'm a mac user!
                .onChange(of: geometry.size) { value in
                    playerModel.playerSize = value
                }
            /// Actions when the View is dismissed
                .onDisappear {
                    Task {
                        if state == .playedToTheEnd {
                            /// Mark as played
                            print("End of video, mark as played")
                            await item.markAsPlayed()
                        } else {
                            /// Set resume time
                            print("Video is playing, set resume point")
                            await item.setResumeTime(time: Double(playerModel.currentTime))
                        }
                    }
                }
                .background(.black)
        }
        .edgesIgnoringSafeArea(.all)
        .animation(.default, value: playerModel.showController)
        .animation(.default, value: state)
        .environmentObject(playerModel)
        .environmentObject(player.coordinator)
    }
    
    /// Format the remaining time
    private func remainingTime(duration: Int) -> String {
        let duration = TimeInterval(duration)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [ .hour, .minute ]
        formatter.zeroFormattingBehavior = [ .default ]
        return "\(formatter.string(from: duration) ?? "Unknown time") to go..."
    }
}
