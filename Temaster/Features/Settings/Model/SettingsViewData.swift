import Foundation
import TemasterData

/// Display-ready data of Settings. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct SettingsViewData: Equatable, Sendable {
    /// Music service the user signed in with, shown in the Account section.
    enum Provider: Equatable, Sendable {
        case spotify
        case appleMusic

        init(_ provider: MusicProvider) {
            switch provider {
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

    /// Who plays each game: every player on their own, the three generations as teams, or the user's own ones.
    enum PlayMode: Hashable, Sendable {
        case individual
        case generations
        case custom
    }

    /// Game settings, returned by `SettingsUseCase` and saved by `SaveSettingsUseCase`.
    struct Game: Equatable, Sendable {
        /// Lengths a clip can have, in seconds, and the step between them.
        static let clipSecondsRange = 5...60
        static let clipSecondsStep = 5

        var playback: Playback
        var clipSeconds: Int
        var clipStart: ClipStart
        var mode: GameMode
        /// Identifier of the Bingo level: the `id` of one of the `bingoLevels`.
        var bingoLevel: String
        var playMode: PlayMode
        /// Generations of the `custom` play mode, in the order they were created.
        var customGenerations: [CustomGeneration]
    }

    /// A generation the user created for the `custom` play mode.
    struct CustomGeneration: Equatable, Sendable, Identifiable {
        let id: String
        var name: String
        /// SF Symbol, one of `symbols`.
        var symbolName: String
        /// Color its icon is painted on.
        var color: BingoColor
        /// First and last release year of its songs, both included.
        /// At least one is set: `nil` first year is «the past», `nil` last year is «today».
        var firstYear: Int?
        var lastYear: Int?

        /// Icons the user can choose from, in the order the picker shows them. The first one is the default.
        static let symbols = [
            "music.note", "music.mic", "guitars.fill", "pianokeys", "headphones", "radio.fill",
            "music.quarternote.3", "mic.fill", "star.fill", "heart.fill", "flame.fill", "sparkles"
        ]
        /// Years a generation can start and end in.
        static let firstAllowedYear = 1900
    }

    /// What the user is typing in the «New generation» sheet, before it is saved.
    struct CustomGenerationDraft: Equatable, Sendable {
        var name = ""
        var symbolName = CustomGeneration.symbols[0]
        var color = BingoColor.cyan
        /// Years as typed. Either can stay empty (the past, or today), but not both.
        var firstYear = ""
        var lastYear = ""
    }

    /// The five Bingo categories, by their color.
    enum BingoColor: Hashable, Sendable {
        case pink
        case yellow
        case cyan
        case green
        case orange
    }

    /// A category of a Bingo level: its color and its name in that level, already localised.
    struct BingoCategory: Equatable, Sendable, Identifiable {
        let color: BingoColor
        let title: String

        var id: BingoColor { color }
    }

    /// A Bingo level with its five categories, returned by `BingoLevelsUseCase`.
    struct BingoLevel: Equatable, Sendable, Identifiable {
        /// Identifier stored in the settings.
        let id: String
        let title: String
        let categories: [BingoCategory]
    }

    /// The three generations of the «Generations» play mode, by their music format.
    enum GenerationKind: Hashable, Sendable {
        case vinyl
        case cassette
        case streaming
    }

    /// A generation of the «Generations» play mode with its name already localised, returned by
    /// `GenerationsUseCase`.
    struct Generation: Equatable, Sendable, Identifiable {
        let kind: GenerationKind
        let title: String

        var id: GenerationKind { kind }
    }

    var provider: Provider
    /// Result of `SettingsUseCase`, or `nil` until it loads.
    var game: Game?
    /// Result of `BingoLevelsUseCase`, in the order Settings shows them. Empty until it loads.
    var bingoLevels: [BingoLevel] = []
    /// Result of `GenerationsUseCase`, in the order Settings shows them. Empty until it loads.
    var generations: [Generation] = []
}
