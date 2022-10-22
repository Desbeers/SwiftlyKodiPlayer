//
//  KodiPlayerView+macOS.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import KSPlayer
import MediaPlayer

#if os(macOS)

extension KodiPlayerView {
    
    // MARK: Gestures
    
    /// Gestures for the macOS player
    public struct PlayerGestures: ViewModifier {
        /// Check if this window is the key window
        @Environment(\.controlActiveState) var controlActiveState
        /// The Coordinator model
        @EnvironmentObject private var config: KSVideoPlayer.Coordinator
        /// The Player model
        @EnvironmentObject var playerModel: KodiPlayerView.PlayerModel
        /// The body of the ViewModifier
        public func body(content: Content) -> some View {
            content
                .task {
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        keyEvent(keyCode: event.keyCode)
                        return nil
                    }
                    registerRemoteControllEvent()
                    await setNowPlayingInfo()
                }
                .onTapGesture(count: 2) {
                    NSApplication.shared.keyWindow?.toggleFullScreen(self)
                }
                .onTapGesture(count: 1) {
                    playerModel.showController.toggle()
                    playerModel.showController ? NSCursor.unhide() : NSCursor.setHiddenUntilMouseMoves(true)
                }
        }
        
        /// Handle keyboard events
        private func keyEvent(keyCode: UInt16) {
            if controlActiveState == .key {
                dump(keyCode)
                switch keyCode {
                case 49:
                    /// Space
                    config.isPlay.toggle()
                case 125:
                    /// Arrow down
                    playerModel.showController.toggle()
                default:
                    break
                }
            }
        }
        
        /// Handle the media keys
        private func registerRemoteControllEvent() {
            let remoteCommand = MPRemoteCommandCenter.shared()
            remoteCommand.playCommand.addTarget { _ in
                print("Play")
                return .success
            }
            remoteCommand.pauseCommand.addTarget { _ in
                print("Pause")
                return .success
            }
            remoteCommand.togglePlayPauseCommand.addTarget { _ in
                print("PlayPause")
                return .success
            }
        }
        
        /// Set the now playing info for the menu bar
        private func setNowPlayingInfo() async {
            var info = [String: Any]()
            info[MPMediaItemPropertyTitle] = playerModel.metaData.title
            if let url = playerModel.metaData.artworkURL {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let artworkImage = NSImage(data: data)!
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
                        artworkImage
                    }
                } catch {
                    /// Ignore it...
                }
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    
    // MARK: Controller
    
    /// Show the controller view
    public struct ShowControllerView: ViewModifier {
        /// The Player model
        @EnvironmentObject var playerModel: KodiPlayerView.PlayerModel
        /// The body of the ViewModifier
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
