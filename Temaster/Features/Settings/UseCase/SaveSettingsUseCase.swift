import Foundation
import TemasterData

protocol SaveSettingsUseCaseProtocol: Sendable {
    /// Stores `game` as the game settings of the music service the user signed in with, replacing the previous ones.
    func execute(game: SettingsViewData.Game) async throws
}

/// Saves the game settings through the Settings repository public API.
struct SaveSettingsUseCase: SaveSettingsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute(game: SettingsViewData.Game) async throws {
        try await repository.saveSettings(SavedSettings(game), for: provider)
    }
}

/// The game settings in the shape the Settings repository stores.
private struct SavedSettings: GameSettingsProtocol {
    let playbackMode: SettingsPlaybackMode
    let clipSeconds: Int
    let clipStart: SettingsClipStart
    let gameMode: SettingsGameMode
    let bingoLevel: SettingsBingoLevel
    let playMode: SettingsPlayMode
    let customGenerations: [any SettingsCustomGenerationProtocol]

    init(_ game: SettingsViewData.Game) {
        self.playbackMode = game.playback == .fullSong ? .fullSong : .clip
        self.clipSeconds = game.clipSeconds
        self.clipStart = game.clipStart == .beginning ? .beginning : .random
        self.gameMode = game.mode == .bingo ? .bingo : .classic
        // The id always comes from a level of the repository; the default only guards against a wrong one.
        self.bingoLevel = SettingsBingoLevel(rawValue: game.bingoLevel) ?? .beginner
        self.playMode = Self.playMode(game.playMode)
        self.customGenerations = game.customGenerations.map(SavedCustomGeneration.init)
    }

    static func playMode(_ mode: SettingsViewData.PlayMode) -> SettingsPlayMode {
        switch mode {
        case .individual: .individual
        case .generations: .generations
        case .custom: .custom
        }
    }
}

/// A custom generation in the shape the Settings repository stores.
private struct SavedCustomGeneration: SettingsCustomGenerationProtocol {
    let id: String
    let name: String
    let symbolName: String
    let color: SettingsCustomGenerationColor
    let firstYear: Int?
    let lastYear: Int?

    init(_ generation: SettingsViewData.CustomGeneration) {
        self.id = generation.id
        self.name = generation.name
        self.symbolName = generation.symbolName
        self.color = Self.color(generation.color)
        self.firstYear = generation.firstYear
        self.lastYear = generation.lastYear
    }

    static func color(_ color: SettingsViewData.BingoColor) -> SettingsCustomGenerationColor {
        switch color {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }
}
