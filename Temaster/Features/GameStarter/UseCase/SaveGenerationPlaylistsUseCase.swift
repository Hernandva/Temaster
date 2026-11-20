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

    /// The playlists of one play mode replace only that mode's last ones: the `generations` ones and the custom ones
    /// are stored apart.
    func execute(playlists: [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist]) async throws {
        var generationPlaylists: [SettingsGeneration: any LastPlaylistItemProtocol] = [:]
        var customPlaylists: [String: any LastPlaylistItemProtocol] = [:]
        for entry in playlists {
            if let generation = entry.key.settingsGeneration {
                generationPlaylists[generation] = Self.savedPlaylist(entry.value)
            } else if let id = entry.key.customGenerationID {
                customPlaylists[id] = Self.savedPlaylist(entry.value)
            }
        }
        if !generationPlaylists.isEmpty {
            try await repository.saveGenerationPlaylists(generationPlaylists, for: provider)
        }
        if !customPlaylists.isEmpty {
            try await repository.saveCustomGenerationPlaylists(customPlaylists, for: provider)
        }
    }
}

private extension SaveGenerationPlaylistsUseCase {
    static func savedPlaylist(_ playlist: GameStarterViewData.Playlist) -> SavedPlaylist {
        SavedPlaylist(id: playlist.id, name: playlist.name, songCount: playlist.songCount, coverURLs: playlist.covers)
    }
}
