import Foundation
import TemasterData

/// Dependency injection container of Game: the only place where its concrete types are built.
@MainActor
final class GameDependencies {
    private let provider: MusicProvider
    private let playlists: [GameViewData.Playlist]
    private let settings: GameViewData.Settings
    private let songRepository: any SongRepositoryProtocol
    private let playerRepository: any PlayerRepositoryProtocol
    private let artistRepository: any ArtistRepositoryProtocol
    private let externalDisplaySession: GameExternalDisplaySession

    /// - Parameters:
    ///   - provider: The music service the user signed in with.
    ///   - playlists: The playlists chosen in GameStarter: one for everyone, or one per generation in turn order.
    ///   - settings: The game settings saved in Settings.
    ///   - externalDisplaySession: Where the game is shown on an external display (a TV through AirPlay).
    init(
        provider: MusicProvider,
        playlists: [GameViewData.Playlist],
        settings: GameViewData.Settings,
        songRepository: any SongRepositoryProtocol = SongRepository(),
        playerRepository: any PlayerRepositoryProtocol = PlayerRepository(),
        artistRepository: any ArtistRepositoryProtocol = ArtistRepository(),
        externalDisplaySession: GameExternalDisplaySession = .shared
    ) {
        self.provider = provider
        self.playlists = playlists
        self.settings = settings
        self.songRepository = songRepository
        self.playerRepository = playerRepository
        self.artistRepository = artistRepository
        self.externalDisplaySession = externalDisplaySession
    }

    /// The music service the user signed in with.
    func resolveProvider() -> MusicProvider {
        provider
    }

    /// The playlists the game is played with, in turn order.
    func resolvePlaylists() -> [GameViewData.Playlist] {
        playlists
    }

    /// The game settings the game is played with.
    func resolveSettings() -> GameViewData.Settings {
        settings
    }

    func resolveSongRepository() -> any SongRepositoryProtocol {
        songRepository
    }

    func resolvePlayerRepository() -> any PlayerRepositoryProtocol {
        playerRepository
    }

    func resolveArtistRepository() -> any ArtistRepositoryProtocol {
        artistRepository
    }

    /// Where the game is shown on an external display, and whether one is connected.
    func resolveExternalDisplaySession() -> GameExternalDisplaySession {
        externalDisplaySession
    }

    func resolveFetchArtistUseCase() -> any FetchArtistUseCaseProtocol {
        FetchArtistUseCase(dependencies: self)
    }

    func resolveGamePlayerUseCase() -> any GamePlayerUseCaseProtocol {
        GamePlayerUseCase(dependencies: self)
    }

    func resolveGamePlayBackStatusUseCase() -> any GamePlayBackStatusUseCaseProtocol {
        GamePlayBackStatusUseCase(dependencies: self)
    }

    func resolveGenerationMixUseCase() -> any GenerationMixUseCaseProtocol {
        GenerationMixUseCase(dependencies: self)
    }

    func resolveFetchGameSongsUseCase() -> any FetchGameSongsUseCaseProtocol {
        FetchGameSongsUseCase(dependencies: self)
    }

    func resolveViewModel() -> GameViewModel {
        GameViewModel(dependencies: self)
    }
}
