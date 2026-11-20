import Foundation

public enum SettingsError: Error, Equatable, Sendable {
    /// The settings could not be written to the local storage.
    case storageFailed
}

/// What each round plays of a song.
public enum SettingsPlaybackMode: String, Codable, Sendable, CaseIterable {
    /// The whole song, before it is revealed.
    case fullSong
    /// A clip of `GameSettingsProtocol.clipSeconds`.
    case clip
}

/// Where a clip starts in the song.
public enum SettingsClipStart: String, Codable, Sendable, CaseIterable {
    case beginning
    case random
}

public enum SettingsGameMode: String, Codable, Sendable, CaseIterable {
    /// One song after another: guess its data.
    case classic
    /// Musical bingo cards.
    case bingo
}

/// Who plays each game: every player on their own, the three generations as teams, or the user's own generations.
public enum SettingsPlayMode: String, Codable, Sendable, CaseIterable {
    /// Every player plays on their own, as the game always did.
    case individual
    /// The players are split into the three `SettingsGeneration`s, which always all play.
    case generations
    /// Generations the user creates. For now the list starts empty and nothing can be added yet.
    case custom
}

/// The three generations of the `generations` play mode, by the music of their time. Every game has all three,
/// in this order. The raw values are stable keys of their names in the app's strings.
public enum SettingsGeneration: String, Sendable, CaseIterable {
    /// Up to 1984.
    case vinyl
    /// From 1985 to 2004.
    case cassette
    /// From 2005.
    case streaming
}

/// One generation of the `generations` play mode, returned by `SettingsRepositoryProtocol.generations()`.
public protocol SettingsGenerationResponseProtocol: Sendable {
    var generation: SettingsGeneration { get }
    /// Key of the generation's name in the app's strings, e.g. `generation.vinyl`.
    var titleKey: String { get }
    /// First release year of the generation's songs, or `nil` when it has no start (`vinyl`).
    var firstYear: Int? { get }
    /// Last release year of the generation's songs, or `nil` when it reaches today (`streaming`).
    var lastYear: Int? { get }
}

/// Difficulty of the Bingo mode. It changes what each category asks. A new level adds a case with a new raw value
/// and its entry in `BingoLevelsCatalog`; the raw values are what is stored, so existing ones never change.
public enum SettingsBingoLevel: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case expert
    case movies
}

/// The five Bingo categories, by their color. Every level has all five, in this order.
public enum SettingsBingoCategory: String, Sendable, CaseIterable {
    case pink
    case yellow
    case cyan
    case green
    case orange
}

/// One category of a Bingo level, returned by `SettingsRepositoryProtocol.bingoLevels()`.
public protocol SettingsBingoCategoryResponseProtocol: Sendable {
    var category: SettingsBingoCategory { get }
    /// Key of the category's name in this level in the app's strings, e.g. `bingo.category.pink.beginner`.
    var titleKey: String { get }
}

/// A Bingo level with its categories, returned by `SettingsRepositoryProtocol.bingoLevels()`.
public protocol SettingsBingoLevelResponseProtocol: Sendable {
    var level: SettingsBingoLevel { get }
    /// Key of the level's name in the app's strings, e.g. `bingo.level.beginner`.
    var titleKey: String { get }
    /// The five categories, in the order of `SettingsBingoCategory`.
    var categories: [any SettingsBingoCategoryResponseProtocol] { get }
}

/// Colors a custom generation can have: the five light colors of the app. The raw values are stored, so they never
/// change.
public enum SettingsCustomGenerationColor: String, Codable, Sendable, CaseIterable {
    case pink
    case yellow
    case cyan
    case green
    case orange
}

/// A generation the user creates for the `custom` play mode.
public protocol SettingsCustomGenerationProtocol: Sendable {
    /// Stable identifier, made by the app when the generation is created.
    var id: String { get }
    var name: String { get }
    /// SF Symbol the user chose for it.
    var symbolName: String { get }
    /// Color its icon is painted on.
    var color: SettingsCustomGenerationColor { get }
    /// First and last release year of its songs, both included. At least one of them is set: `nil` first year is
    /// «the past» (any year up to the last one), `nil` last year is «today» (any year from the first one).
    var firstYear: Int? { get }
    var lastYear: Int? { get }
}

/// The game settings, as the app stores and shows them.
public protocol GameSettingsProtocol: Sendable {
    var playbackMode: SettingsPlaybackMode { get }
    /// Length of a clip, in seconds (5 to 60, in steps of 5).
    var clipSeconds: Int { get }
    var clipStart: SettingsClipStart { get }
    var gameMode: SettingsGameMode { get }
    var bingoLevel: SettingsBingoLevel { get }
    var playMode: SettingsPlayMode { get }
    /// Generations of the `custom` play mode, in the order they were created. Empty until the user adds one.
    var customGenerations: [any SettingsCustomGenerationProtocol] { get }
}

/// Public data the Settings repository returns to the app: the saved settings, or the default ones.
public protocol SettingsResponseProtocol: GameSettingsProtocol {}
