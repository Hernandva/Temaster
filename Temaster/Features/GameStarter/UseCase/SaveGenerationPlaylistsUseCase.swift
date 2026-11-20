import Foundation
import TemasterData

protocol SaveGenerationPlaylistsUseCaseProtocol: Sendable {
    /// Stores the playlist of each generation as their last ones for the music service the user signed in with,
    /// replacing the previous ones.
    func execute(playlists: [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist]) async throws
}

/// Saves the generations' playlists the game starts with through the LastPlaylist repository public API, so each
/// generation finds its own playlist next time.
struct SaveGenerationPlaylistsUseCase: SaveGenerationPlaylistsUseCaseProtocol {
    private let provider: MusicProvider
    private let repository: any LastPlaylistRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameStarterDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameStarterDependencies) {
        self.provider = dependencies.resolveProvider()
        self.repository = dependencies.resolveRepository()
    }

    func execute(playlists: [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist]) async throws {
        var savedPlaylists: [SettingsGeneration: any LastPlaylistItemProtocol] = [:]
        for entry in playlists {
            savedPlaylists[entry.key.settingsGeneration] = SavedPlaylist(
                id: entry.value.id,
                name: entry.value.name,
                songCount: entry.value.songCount,
                coverURLs: entry.value.covers
            )
        }
        try await repository.saveGenerationPlaylists(savedPlaylists, for: provider)
    }
}
