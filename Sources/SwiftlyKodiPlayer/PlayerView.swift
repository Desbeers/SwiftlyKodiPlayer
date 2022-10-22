//
//  PlayerView.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import AVFoundation
import AVKit
import SwiftUI
import KSPlayer
import SwiftlyKodiAPI

/// The Video Player View
public struct PlayerView: View {
    /// The video we want to play
    let video: any KodiItem
    /// The Player model
    @StateObject var playerModel: PlayerModel
    
    @EnvironmentObject private var config: KSVideoPlayer.Coordinator
    /// Dismiss the window
    @Environment(\.dismiss) private var dismiss
    /// The actual player
    let player: KSVideoPlayer
    /// Init the player with the video
    public init(video: any KodiItem, resume: Bool = false) {
        let url = URL(string: Files.getFullPath(file: video.file, type: .file))!
        let options = KSOptions()
        if resume {
            options.startPlayTime = video.resume.position
        }
        player = KSVideoPlayer(url: url, options: options)
        _playerModel = StateObject(wrappedValue: PlayerModel(video: video))
        self.video = video
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
                .onStateChanged { layer, state in
                    playerModel.state = state
                    switch state {
                    case .prepareToPlay:
                        break
                    case .readyToPlay:
                        if let track = player.coordinator.subtitleTracks.first {
                            player.coordinator.selectedSubtitleTrack = track
                        }
                    case .buffering:
                        break
                    case .bufferFinished:
                        if playerModel.showController {
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + KSOptions.animateDelayTimeInterval) {
                                playerModel.showController = false
                            }
                        }
                        playerModel.naturalSize = layer.player.naturalSize
                    case .paused:
                        playerModel.showController = true
                    case .playedToTheEnd:
                        /// Close the view
                        dismiss()
                    case .error:
                        break
                    }
                }
#if os(tvOS)
                .onSwipe { direction in
                    if direction == .down {
                        playerModel.showController.toggle()
                    } else if direction == .left {
                        player.coordinator.skip(interval: -15)
                    } else if direction == .right {
                        player.coordinator.skip(interval: 15)
                    }
                }
            /// This is needed or else 'onMoveCommand' does not work
                .focusable()
                .onMoveCommand { direction in  // <-- this $#!* can't tell a move swipe from a touch (direction is of type: MoveCommandDirection)
                    print("Direction: \(direction)")
                    if direction == .left { print(">>> left swipe detected") }
                    if direction == .right { print(">>> right swipe detected") }
                    if direction == .up { print(">>> up swipe detected") }
                    if direction == .down {
                        print(">>> down swipe detected")
                        playerModel.showController.toggle()
                    }
                }
#endif
#if !os(tvOS)
                .onTapGesture {
                    playerModel.showController.toggle()
#if os(macOS)
                    playerModel.showController ? NSCursor.unhide() : NSCursor.setHiddenUntilMouseMoves(true)
#endif
                }
#endif
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
            
            
                .overlay(alignment: .bottom) {
                    SubtitleView()
                }
                .overlay(alignment: .center) {
                    ProgressView().opacity(playerModel.state == .buffering ? 1 : 0)
                        .tint(.white)
                }
                .controller()
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
                        if playerModel.state == .playedToTheEnd {
                            /// Mark as played
                            print("End of video, mark as played")
                            await video.markAsPlayed()
                        } else {
                            /// Set resume time
                            print("Video is playing, set resume point")
                            await video.setResumeTime(time: Double(playerModel.currentTime))
                        }
                    }
                }
                .background(.black)
        }
        .edgesIgnoringSafeArea(.all)
        .animation(.default, value: playerModel.showController)
        .environmentObject(playerModel)
        .environmentObject(player.coordinator)
    }
}
