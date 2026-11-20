import Foundation

/// Stored format of the game settings. Internal to TemasterData: the app only sees SettingsResponseProtocol.
struct GameSettingsDAO: Codable, Sendable, Equatable, SettingsResponseProtocol {
    /// Settings of a first launch: 30-second clips from a random point, classic mode, beginner Bingo level,
    /// every player on their own.
    static let defaults = GameSettingsDAO(
        playbackMode: .clip,
        clipSeconds: 30,
        clipStart: .random,
        gameMode: .classic,
        bingoLevel: .beginner,
        playMode: .individual
    )

    let playbackMode: SettingsPlaybackMode
    let clipSeconds: Int
    let clipStart: SettingsClipStart
    let gameMode: SettingsGameMode
    let bingoLevel: SettingsBingoLevel
    let playMode: SettingsPlayMode

    init(
        playbackMode: SettingsPlaybackMode,
        clipSeconds: Int,
        clipStart: SettingsClipStart,
        gameMode: SettingsGameMode,
        bingoLevel: SettingsBingoLevel,
        playMode: SettingsPlayMode
    ) {
        self.playbackMode = playbackMode
        self.clipSeconds = clipSeconds
        self.clipStart = clipStart
        self.gameMode = gameMode
        self.bingoLevel = bingoLevel
        self.playMode = playMode
    }

    init(_ settings: some GameSettingsProtocol) {
        self.init(
            playbackMode: settings.playbackMode,
            clipSeconds: settings.clipSeconds,
            clipStart: settings.clipStart,
            gameMode: settings.gameMode,
            bingoLevel: settings.bingoLevel,
            playMode: settings.playMode
        )
    }

    /// A field that is missing, e.g. one added in a later version, takes its default value,
    /// so the rest of the saved settings is kept. Fields no longer used, such as the old
    /// `disabledBingoCategories` or `sharedPlaylist`, are ignored.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults
        self.init(
            playbackMode: try container.decodeIfPresent(SettingsPlaybackMode.self, forKey: .playbackMode)
                ?? defaults.playbackMode,
            clipSeconds: try container.decodeIfPresent(Int.self, forKey: .clipSeconds) ?? defaults.clipSeconds,
            clipStart: try container.decodeIfPresent(SettingsClipStart.self, forKey: .clipStart) ?? defaults.clipStart,
            gameMode: try container.decodeIfPresent(SettingsGameMode.self, forKey: .gameMode) ?? defaults.gameMode,
            // A level this version does not know, e.g. saved by a newer one, reads as the default level
            // instead of losing every setting.
            bingoLevel: (try? container.decodeIfPresent(SettingsBingoLevel.self, forKey: .bingoLevel))
                ?? defaults.bingoLevel,
            playMode: (try? container.decodeIfPresent(SettingsPlayMode.self, forKey: .playMode))
                ?? defaults.playMode
        )
    }
}
