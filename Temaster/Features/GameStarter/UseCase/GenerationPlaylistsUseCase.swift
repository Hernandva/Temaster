import Foundation
import TemasterData

protocol GenerationPlaylistsUseCaseProtocol: Sendable {
    /// Returns the generations that each play with their own playlist, names already localised: all of them in the
    /// `generations` play mode without «Play with the same playlist», none otherwise (one playlist for everyone).
    /// The view model adds them to its `GameStarterViewData`.
    func execute() async throws -> [GameStarterViewData.Generation]
}

/// Reads the play mode of the music service through the Settings repository public API, so the screen knows how
/// many playlists to ask for.
struct GenerationPlaylistsUseCase: GenerationPlaylistsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveSettingsRepository()
    }

    func execute() async throws -> [GameStarterViewData.Generation] {
        let response = try await repository.fetch(GameSettingsRequest(provider: provider))
        guard response.playMode == .generations, !response.sharedPlaylist else { return [] }
        return await repository.generations().map(Self.generation)
    }
}

private extension GenerationPlaylistsUseCase {
    /// Maps a generation of the repository into the data the view model adds to its ViewData.
    static func generation(_ response: any SettingsGenerationResponseProtocol) -> GameStarterViewData.Generation {
        GameStarterViewData.Generation(
            kind: GameStarterViewData.GenerationKind(response.generation),
            title: String(localized: String.LocalizationValue(response.titleKey)),
            firstYear: response.firstYear,
            lastYear: response.lastYear
        )
    }
}
