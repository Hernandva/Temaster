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

/// Who plays each game: every player on their own, or the three generations as teams.
public enum SettingsPlayMode: String, Codable, Sendable, CaseIterable {
    /// Every player plays on their own, as the game always did.
    case individual
    /// The players are split into the three `SettingsGeneration`s, which always all play.
    case generations
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

/// The game settings, as the app stores and shows them.
public protocol GameSettingsProtocol: Sendable {
    var playbackMode: SettingsPlaybackMode { get }
    /// Length of a clip, in seconds (5 to 60, in steps of 5).
    var clipSeconds: Int { get }
    var clipStart: SettingsClipStart { get }
    var gameMode: SettingsGameMode { get }
    var bingoLevel: SettingsBingoLevel { get }
    var playMode: SettingsPlayMode { get }
    /// In the `generations` play mode, whether the three generations play with the same playlist.
    /// It is always `true` in the `individual` play mode.
    var sharedPlaylist: Bool { get }
}

/// Public data the Settings repository returns to the app: the saved settings, or the default ones.
public protocol SettingsResponseProtocol: GameSettingsProtocol {}
