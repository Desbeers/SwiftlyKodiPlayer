//
//  KodiPlayerView.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import AVFoundation
import AVKit
import SwiftUI
import KSPlayer
import SwiftlyKodiAPI

/// The Kodi Player View
public struct KodiPlayerView: View {
    /// The item we want to play
    let item: any KodiItem
    /// The Player model
    @StateObject var playerModel: PlayerModel
    
    @EnvironmentObject private var config: KSVideoPlayer.Coordinator
    /// Dismiss the window
    @Environment(\.dismiss) private var dismiss
    /// The actual player
    let player: KSVideoPlayer
    /// Init the player with the video
    public init(item: any KodiItem, resume: Bool = false) {
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
        .environmentObject(playerModel)
        .environmentObject(player.coordinator)
    }
}
