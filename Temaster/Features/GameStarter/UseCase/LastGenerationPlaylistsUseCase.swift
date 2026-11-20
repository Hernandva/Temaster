import Foundation
import TemasterData

protocol LastGenerationPlaylistsUseCaseProtocol: Sendable {
    /// Returns the playlist each generation last played with, for the music service the user signed in with; a
    /// generation without one is missing. The view model adds them to its `GameStarterViewData`.
    func execute() async throws -> [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist]
}

/// Reads the generations' last playlists through the LastPlaylist repository public API, so their cards show them
/// again in the next game.
struct LastGenerationPlaylistsUseCase: LastGenerationPlaylistsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any LastPlaylistRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist] {
        let response = try await repository.fetch(LastPlaylistRequest(provider: provider))
        return response.generationPlaylists.reduce(into: [:]) { playlists, entry in
            playlists[GameStarterViewData.GenerationKind(entry.key)] = GameStarterViewData.Playlist(
                id: entry.value.id,
                name: entry.value.name,
                songCount: entry.value.songCount,
                covers: entry.value.coverURLs
            )
        }
    }
}
