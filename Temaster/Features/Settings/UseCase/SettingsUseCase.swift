import Foundation
import TemasterData

protocol SettingsUseCaseProtocol: Sendable {
    /// Returns only the game settings. The view model adds them to its `SettingsViewData`.
    func execute() async throws -> SettingsViewData.Game
}

/// Request sent to the Settings repository: the music service the user signed in with, which has its own settings.
struct SettingsRequest: SettingsRequestProtocol {
    let provider: MusicProvider
}

/// Business logic of Settings: reads the game settings of the signed-in music service through the Settings repository public API and returns
/// them mapped out of the TemasterData types.
struct SettingsUseCase: SettingsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `SettingsDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> SettingsViewData.Game {
        let response = try await repository.fetch(SettingsRequest(provider: provider))
        return Self.game(from: response)
    }
}

private extension SettingsUseCase {
    /// Maps SettingsResponseProtocol into the data the view model adds to its ViewData.
    static func game(from response: any SettingsResponseProtocol) -> SettingsViewData.Game {
        SettingsViewData.Game(
            playback: response.playbackMode == .fullSong ? .fullSong : .clip,
            clipSeconds: clipSeconds(response.clipSeconds),
            clipStart: response.clipStart == .beginning ? .beginning : .random,
            mode: response.gameMode == .bingo ? .bingo : .classic,
            bingoLevel: response.bingoLevel.rawValue,
            playMode: playMode(response.playMode),
            customGenerations: response.customGenerations.map { generation in
                SettingsViewData.CustomGeneration(
                    id: generation.id,
                    name: generation.name,
                    symbolName: generation.symbolName,
                    color: color(generation.color),
                    firstYear: generation.firstYear,
                    lastYear: generation.lastYear
                )
            }
        )
    }

    static func color(_ color: SettingsCustomGenerationColor) -> SettingsViewData.BingoColor {
        switch color {
        case .pink: .pink
        case .yellow: .yellow
        case .cyan: .cyan
        case .green: .green
        case .orange: .orange
        }
    }

    static func playMode(_ mode: SettingsPlayMode) -> SettingsViewData.PlayMode {
        switch mode {
        case .individual: .individual
        case .generations: .generations
        case .custom: .custom
        }
    }

    /// Keeps a stored length inside the range and on a step of the slider.
    static func clipSeconds(_ seconds: Int) -> Int {
        let range = SettingsViewData.Game.clipSecondsRange
        let step = SettingsViewData.Game.clipSecondsStep
        let stepped = (seconds + step / 2) / step * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}
