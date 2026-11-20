import Foundation
import TemasterData

/// Display-ready data of GameStarter. The view model owns it and adds each use case result to its own field.
struct GameStarterViewData: Equatable, Sendable {
    /// Music service the user signed in with.
    enum Provider: Equatable, Sendable {
        case spotify
        case appleMusic

        init(_ musicProvider: MusicProvider) {
            switch musicProvider {
            case .spotify: self = .spotify
            case .appleMusic: self = .appleMusic
            }
        }

        /// Brand name of the service. Brand names are not translated.
        var displayName: String {
            switch self {
            case .spotify: "Spotify"
            case .appleMusic: "Apple Music"
            }
        }
    }

    /// A playlist shown in the selected playlist card. `Hashable` because the Game route carries it.
    struct Playlist: Hashable, Sendable {
        /// Identifier of the playlist in its music service.
        let id: String
        let name: String
        /// `nil` when it was chosen in the selector, which does not read the songs.
        let songCount: Int?
        let covers: [URL]
    }

    /// What each round plays of a song.
    enum Playback: Hashable, Sendable {
        case fullSong
        case clip
    }

    /// Where a clip starts in the song.
    enum ClipStart: Hashable, Sendable {
        case beginning
        case random
    }

    enum GameMode: Hashable, Sendable {
        case classic
        case bingo
    }

    /// The five Bingo categories, by their color.
    enum BingoColor: Hashable, Sendable {
        case pink
        case yellow
        case cyan
        case green
        case orange
    }

    /// A Bingo category of the level in the settings: its color and its name in that level, already localised.
    struct BingoCategory: Hashable, Sendable {
        let color: BingoColor
        let title: String
    }

    /// Game settings of the music service, read when Play is tapped.
    /// `Hashable` because the Game route carries them.
    struct GameSettings: Hashable, Sendable {
        var playback: Playback
        /// Length of a clip, in seconds.
        var clipSeconds: Int
        var clipStart: ClipStart
        var mode: GameMode
        /// Name of the Bingo level, already localised («Principiante»).
        var bingoLevelTitle: String
        /// The five categories of the Bingo level, from the Settings repository.
        var bingoCategories: [BingoCategory]
    }

    /// A generation that plays with its own playlist: one of the three of the «Generations» play mode, or one the
    /// user created for the «Custom» play mode, by its id. `Hashable` because the playlist selector route carries the
    /// one it chooses for.
    enum GenerationKind: Hashable, Sendable {
        case vinyl
        case cassette
        case streaming
        case custom(id: String)
    }

    /// Icon and color the user chose for a custom generation. The three of the «Generations» play mode have a fixed
    /// look, so they have none.
    struct CustomLook: Hashable, Sendable {
        /// SF Symbol of the generation.
        let symbolName: String
        let color: BingoColor
    }

    /// A generation that plays with its own playlist: its kind, its name, already localised, and the release years
    /// of its songs, which the game uses to mix each playlist.
    struct Generation: Hashable, Sendable, Identifiable {
        let kind: GenerationKind
        let title: String
        /// `nil` when the generation has no first year (vinyl).
        let firstYear: Int?
        /// `nil` when the generation reaches today (streaming).
        let lastYear: Int?
        /// The icon and color of a custom generation; `nil` for the three of the «Generations» play mode.
        var customLook: CustomLook?

        var id: GenerationKind { kind }
    }

    /// A playlist Play hands to the game: everyone's, or the one `generation` plays with. `Hashable` because the
    /// Game route carries it.
    struct GamePlaylist: Hashable, Sendable {
        let playlist: Playlist
        /// `nil` when everyone plays with `playlist`.
        let generation: Generation?
    }

    /// Known before anything loads: it comes from Home.
    var provider: Provider
    /// Result of `LastPlaylistUseCase`. `nil` until it loads, or when no playlist has been played yet.
    var lastPlaylist: Playlist?
    /// Playlist chosen in the playlist selector. When there is one, it is shown and played instead of
    /// `lastPlaylist`, and Play saves it as the new last playlist.
    var selectedPlaylist: Playlist?
    /// Result of `GenerationPlaylistsUseCase`: the generations that each choose their own playlist. Empty when
    /// everyone plays with `selectedPlaylist` (the `individual` play mode, or `custom` with no generations yet).
    var generations: [Generation] = []
    /// Result of `LastGenerationPlaylistsUseCase`: the playlist each generation last played with. A generation's card
    /// shows it until one is chosen for it in the selector.
    var lastGenerationPlaylists: [GenerationKind: Playlist] = [:]
    /// Playlist chosen in the playlist selector for each of `generations`. It is shown and played instead of the
    /// generation's one in `lastGenerationPlaylists`, and Play saves them as the new last ones.
    var generationPlaylists: [GenerationKind: Playlist] = [:]
    /// Result of `GameSettingsUseCase`: the settings the last game started with. `nil` until Play is tapped.
    var gameSettings: GameSettings?
}
