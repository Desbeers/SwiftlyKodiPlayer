//
//  PlayerView.swift
//  Kodio
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
#if canImport(UIKit)
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
                .onReceive(player.coordinator.$selectedSubtitleTrack) { track in
                    guard let subtitle = track as? SubtitleInfo else {
                        playerModel.selectedSubtitle = nil
                        return
                    }
                    subtitle.enableSubtitle { result in
                        playerModel.selectedSubtitle = try? result.get()
                    }
                }
            
                .onDisappear {
                    Task {
                        if playerModel.state == .playedToTheEnd {
                            /// Mark as played
                            print("End of video, mark as played")
                            await video.markAsPlayed()
                        } else {
                            dump(playerModel.currentTime)
                            /// Set resume time
                            print("Video is playing, set resume point")
                            await video.setResumeTime(time: Double(playerModel.currentTime))
                        }
                    }
                    if let playerLayer = player.coordinator.playerLayer {
                        if !playerLayer.isPipActive {
                            player.coordinator.playerLayer?.pause()
                        }
                    }
                }
#if os(iOS)
                .overlay(alignment: .topLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark").imageScale(.large)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .opacity(playerModel.showController ? 1 : 0)
                }

            #else
                .overlay(alignment: .bottom) {
                    if playerModel.showController {
                        ControllerView()
                    }
                }
#endif
                .overlay(alignment: .bottom) {
                    SubtitleView()
                }
#if canImport(UIKit)
                .fullScreenCover(isPresented: $playerModel.showController) {
                    VStack {
                        Spacer()
                        ControllerView()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
#endif
                .overlay(alignment: .center) {
                    ProgressView().opacity(playerModel.state == .buffering ? 1 : 0)
#if !os(tvOS)
                        .keyboardShortcut(.space, modifiers: .none)
#endif
                }
                .edgesIgnoringSafeArea(.all)
                .onChange(of: geometry.size) { value in
                    playerModel.playerSize = value
                }
                .task {
                    /// Store the View size
                    playerModel.playerSize = geometry.size
                    /// Load the poster art
                    if let url = playerModel.metaData.artworkURL {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
#if os(macOS)
                            playerModel.metaData.artwork = Image(nsImage: NSImage(data: data)!)
#else
                            playerModel.metaData.artwork = Image(uiImage: UIImage(data: data)!)
#endif
                        } catch {
                            /// Ignore
                        }
                    }
                }
                .background(.black)
        }
        .animation(.default, value: playerModel.showController)
        //.preferredColorScheme(.dark)
        .environmentObject(playerModel)
        .environmentObject(player.coordinator)
        
        //#if os(tvOS)
        //.onPlayPauseCommand {
        //    print("Toggle Play")
        //    config.isPlay.toggle()
        //}
        //#endif
        
#if os(macOS)
        .onTapGesture(count: 2) {
            print("FULL")
            NSApplication.shared.keyWindow?.toggleFullScreen(self)
        }
        
        .gesture(TapGesture(count: 2).onEnded {
            print("double clicked")
        })
#else
        .navigationBarHidden(true)
#endif
    }
}

extension EventModifiers {
    static let none = Self()
}

#if os(tvOS)
import Combine
public struct Slider: UIViewRepresentable {
    private let process: Binding<Float>
    private let onEditingChanged: (Bool) -> Void
    init(value: Binding<Double>, in bounds: ClosedRange<Double> = 0 ... 1, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        process = Binding {
            Float((value.wrappedValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound))
        } set: { newValue in
            value.wrappedValue = (bounds.upperBound - bounds.lowerBound) * Double(newValue) + bounds.lowerBound
        }
        self.onEditingChanged = onEditingChanged
    }
    
    public typealias UIViewType = TVSlide
    public func makeUIView(context _: Context) -> UIViewType {
        TVSlide(process: process, onEditingChanged: onEditingChanged)
    }
    
    public func updateUIView(_ view: UIViewType, context _: Context) {
        view.process = process
        view.tintColor = view.isFocused ? .white : .black
    }
}

public class TVSlide: UIControl {
    private let processView = UIProgressView()
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(actionPanGesture(sender:)))
    private var beganProgress = Float(0.0)
    private let onEditingChanged: (Bool) -> Void
    fileprivate var process: Binding<Float> {
        willSet {
            if newValue.wrappedValue != processView.progress {
                processView.progress = newValue.wrappedValue
            }
        }
    }
    
    public init(process: Binding<Float>, onEditingChanged: @escaping (Bool) -> Void) {
        self.process = process
        self.onEditingChanged = onEditingChanged
        super.init(frame: .zero)
        processView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(processView)
        NSLayoutConstraint.activate([
            processView.topAnchor.constraint(equalTo: topAnchor),
            processView.leadingAnchor.constraint(equalTo: leadingAnchor),
            processView.trailingAnchor.constraint(equalTo: trailingAnchor),
            processView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        addGestureRecognizer(panGestureRecognizer)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(actionTapGesture(sender:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func actionTapGesture(sender _: UITapGestureRecognizer) {
        panGestureRecognizer.isEnabled.toggle()
        processView.tintColor = panGestureRecognizer.isEnabled ? .blue : .white
    }
    
    @objc private func actionPanGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        if abs(translation.y) > abs(translation.x) {
            return
        }
        
        switch sender.state {
        case .began, .possible:
            beganProgress = processView.progress
        case .changed:
            let value = beganProgress + Float(translation.x) / 5 / Float(frame.size.width)
            process.wrappedValue = value
            onEditingChanged(true)
        case .ended:
            onEditingChanged(false)
        case .cancelled, .failed:
            process.wrappedValue = beganProgress
            onEditingChanged(false)
        @unknown default:
            break
        }
    }
}
#endif
