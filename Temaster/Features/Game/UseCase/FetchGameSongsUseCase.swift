import Foundation
import TemasterData

protocol FetchGameSongsUseCaseProtocol: Sendable {
    /// Returns every song of the playlist, in their order. The view model shuffles them into the game queue.
    func execute(playlistID: String, provider: MusicProvider) async throws -> [GameViewData.Song]
    /// Returns the songs of each playlist, in their order, at the same index as its identifier. The playlists are
    /// read at the same time.
    func execute(playlistIDs: [String], provider: MusicProvider) async throws -> [[GameViewData.Song]]
}

/// Songs of the game: reads the whole playlist through the Song repository public API, one page
/// (`SongRepository.songsPageSize`) at a time, the same way the selector's `FetchSongsFromPlaylistUseCase` does.
/// It is not named `FetchSongsFromPlaylistUseCase` because that one lives in the same app target.
struct FetchGameSongsUseCase: FetchGameSongsUseCaseProtocol {
    private let repository: any SongRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolveSongRepository()
    }

    func execute(playlistIDs: [String], provider: MusicProvider) async throws -> [[GameViewData.Song]] {
        try await withThrowingTaskGroup(of: (Int, [GameViewData.Song]).self) { group in
            for (index, playlistID) in playlistIDs.enumerated() {
                group.addTask {
                    (index, try await execute(playlistID: playlistID, provider: provider))
                }
            }
            var songsByPlaylist = Array(repeating: [GameViewData.Song](), count: playlistIDs.count)
            for try await (index, songs) in group {
                songsByPlaylist[index] = songs
            }
            return songsByPlaylist
        }
    }

    func execute(playlistID: String, provider: MusicProvider) async throws -> [GameViewData.Song] {
        var songs: [GameViewData.Song] = []
        var offset = 0
        var hasMore = true
        while hasMore {
            try Task.checkCancellation()
            let request = FetchSongsFromPlaylistRequest(provider: provider, playlistID: playlistID, offset: offset)
            let response: any PlaylistSongsResponseProtocol
            do {
                response = try await repository.fetchSongs(request)
            } catch SongError.playlistNotFound where offset == 0 {
                // The Apple Music API answers 404 for the songs of an empty library playlist.
                return []
            }
            songs += response.songs.map { song in
                GameViewData.Song(
                    id: song.id,
                    title: song.title,
                    artist: song.artistName,
                    cover: song.artworkURL,
                    duration: song.duration,
                    catalogID: song.catalogID,
                    album: song.albumName,
                    releaseYear: song.releaseYear,
                    largeCover: song.largeArtworkURL,
                    isrc: song.isrc
                )
            }
            offset += response.songs.count
            // An empty page would never move the offset forward.
            hasMore = response.hasMore && !response.songs.isEmpty
        }
        return songs
    }
}
