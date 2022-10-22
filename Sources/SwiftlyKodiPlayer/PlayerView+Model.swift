//
//  PlayerView+Model.swift
//  SwiftlyKodiPlayer
//
//  © 2022 Nick Berendsen
//

import SwiftUI
import KSPlayer
import SwiftlyKodiAPI

extension PlayerView {
    
    /// The model for the video player
    public class PlayerModel: ObservableObject {
        
        /// # General
        
        /// The video we want to see
        public var video: any KodiItem
        /// Show or hide the video controller
        @Published public var showController: Bool = false {
            didSet {
                setSubtitleOffset()
            }
        }
        /// The metadata of the video
        public var metaData: MetaData
        /// The state of the player
        public var state: KSPlayerState = .buffering
        /// The selected tab
        @Published var selectedTab: Tabs = .info
        
        /// # Video size
        
        /// The natural size of the video
        @Published public var naturalSize = CGSize() {
            didSet {
                print("Natural size set")
                dump(naturalSize)
                setSubtitleOffset()
            }
        }
        /// The size of the PlayerView
        @Published public var playerSize = CGSize() {
            didSet {
                print("Player size set")
                
                dump(playerSize)
                
                setSubtitleOffset()
            }
        }
        
        /// # Time
        
        /// The current time of the video
        public var currentTime = 0
        /// The total time of the video
        public var totalTime = 1
        
        /// # Subtitles
        
        public var selectedSubtitle: KSSubtitleProtocol?
        public var subtitleFont: Font {
            Font(.init(.system, size: playerSize.width / 40))
        }
        @Published public var subtitleOffset: Double = 0
        @Published public var subtitleText: NSMutableAttributedString?
        public var subtitleTime = TimeInterval(0)
        
        /// Init the model with the current video
        init(video: any KodiItem) {
            self.video = video
            metaData = PlayerModel.getMetaData(video: video)
        }

        /// Meta data struct
        public struct MetaData {
            public var title: String = "title"
            public var subtitle: String = "subtitle"
            public var description: String = "description"
            public var genre: String = "genre"
            public var creationDate: String = "1900"
            public var artwork: Image = Image(systemName: "film")
            public var artworkURL: URL?
        }
        
        /// The controller tabs
        enum Tabs: String {
            case info
            case audio
            case subtitles
        }
        
        func getArtwork() async {
            if let url = metaData.artworkURL {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
#if os(macOS)
                    metaData.artwork = Image(nsImage: NSImage(data: data)!)
#else
                    metaData.artwork = Image(uiImage: UIImage(data: data)!)
#endif
                } catch {
                    /// Ignore it...
                }
            }
        }
        
        static func getMetaData(video: any KodiItem) -> MetaData {
            var metaData = MetaData()
            
            switch video {
            case let movie as Video.Details.Movie:
                metaData.title = movie.title
                metaData.subtitle = movie.tagline
                metaData.description = movie.plot
                if !movie.art.poster.isEmpty, let url = URL(string: Files.getFullPath(file: movie.art.poster, type: .art)) {
                    metaData.artworkURL = url
                }
                metaData.genre = movie.genre.joined(separator: " ∙ ")
                metaData.creationDate = movie.year.description
            case let episode as Video.Details.Episode:
                metaData.title = episode.title
                metaData.subtitle = episode.showTitle
                metaData.description = episode.plot
                if !episode.art.seasonPoster.isEmpty, let url = URL(string: Files.getFullPath(file: episode.art.seasonPoster, type: .art)) {
                    metaData.artworkURL = url
                }
                metaData.genre = episode.showTitle
                metaData.creationDate = "\(episode.firstAired)"
            case let musicVideo as Video.Details.MusicVideo:
                metaData.title = musicVideo.title
                metaData.subtitle = musicVideo.subtitle
                metaData.description = musicVideo.plot
                if !musicVideo.art.poster.isEmpty, let url = URL(string: Files.getFullPath(file: musicVideo.art.poster, type: .art)) {
                    metaData.artworkURL = url
                }
                metaData.genre = musicVideo.genre.joined(separator: " ∙ ")
                metaData.creationDate = musicVideo.year.description
            default:
                break
            }
            
            return metaData
        }
        

    }
}

extension PlayerView.PlayerModel {
#if os(tvOS)
    static let controllerHeight: Double = 300
#elseif os(macOS)
    static let controllerHeight: Double = 140
#else
    static let controllerHeight: Double = 200
#endif
}
