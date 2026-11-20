import Foundation
import TemasterData

protocol LastGenerationPlaylistsUseCaseProtocol: Sendable {
    /// Returns the playlist each generation (of the `generations` play mode and the user's custom ones) last played
    /// with, for the music service the user signed in with; a generation without one is missing. The view model adds them to its `GameStarterViewData`.
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
        var playlists: [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist] = [:]
        for entry in response.generationPlaylists {
            playlists[GameStarterViewData.GenerationKind(entry.key)] = Self.playlist(from: entry.value)
        }
        for entry in response.customGenerationPlaylists {
            playlists[.custom(id: entry.key)] = Self.playlist(from: entry.value)
        }
        return playlists
    }
}

private extension LastGenerationPlaylistsUseCase {
    static func playlist(from playlist: any LastPlaylistItemProtocol) -> GameStarterViewData.Playlist {
        GameStarterViewData.Playlist(
            id: playlist.id,
            name: playlist.name,
            songCount: playlist.songCount,
            covers: playlist.coverURLs
        )
    }
}
