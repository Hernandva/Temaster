import Foundation
import TemasterData

protocol FetchGameSongsUseCaseProtocol: Sendable {
    /// Returns every song of the playlist, in their order. The view model shuffles them into the game queue.
    func execute(playlistID: String, provider: MusicProvider) async throws -> [GameViewData.Song]
    /// Returns the songs of each playlist at the same index. The playlists are read at the same time, and a
    /// generation's one is mixed by release year (`GenerationMixUseCase`) so most of its songs are of its time.
    func execute(playlists: [GameViewData.Playlist], provider: MusicProvider) async throws -> [[GameViewData.Song]]
}

/// Songs of the game: reads the whole playlist through the Song repository public API, one page
/// (`SongRepository.songsPageSize`) at a time, the same way the selector's `FetchSongsFromPlaylistUseCase` does.
/// It is not named `FetchSongsFromPlaylistUseCase` because that one lives in the same app target.
struct FetchGameSongsUseCase: FetchGameSongsUseCaseProtocol {
    private let repository: any SongRepositoryProtocol
    private let mixUseCase: any GenerationMixUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `GameDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: GameDependencies) {
        self.repository = dependencies.resolveSongRepository()
        self.mixUseCase = dependencies.resolveGenerationMixUseCase()
    }

    func execute(playlists: [GameViewData.Playlist], provider: MusicProvider) async throws -> [[GameViewData.Song]] {
        let generations = playlists.compactMap(\.generation)
        return try await withThrowingTaskGroup(of: (Int, [GameViewData.Song]).self) { group in
            for (index, playlist) in playlists.enumerated() {
                group.addTask {
                    let songs = try await execute(playlistID: playlist.id, provider: provider)
                    guard let generation = playlist.generation else { return (index, songs) }
                    return (index, mixUseCase.execute(songs: songs, generation: generation, generations: generations))
                }
            }
            var songsByPlaylist = Array(repeating: [GameViewData.Song](), count: playlists.count)
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
