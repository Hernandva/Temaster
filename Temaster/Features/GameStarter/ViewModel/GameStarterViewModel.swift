import Foundation
import Observation

@MainActor
@Observable
final class GameStarterViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: GameStarterViewData

    /// `true` while Play saves the selected playlist.
    private(set) var isStartingGame = false
    /// Shown under Play when the selected playlist could not be saved.
    private(set) var playErrorMessage: String?
    /// `true` while the sheet that offers to change the music service is shown.
    var isChangeProviderSheetPresented = false
    /// Set when the user chose to go back to Home: the view pops once the sheet has closed.
    private(set) var wantsToReturnHome = false

    private let lastPlaylistUseCase: any LastPlaylistUseCaseProtocol
    private let saveLastPlaylistUseCase: any SaveLastPlaylistUseCaseProtocol
    private let gameSettingsUseCase: any GameSettingsUseCaseProtocol
    private let generationPlaylistsUseCase: any GenerationPlaylistsUseCaseProtocol
    private let lastGenerationPlaylistsUseCase: any LastGenerationPlaylistsUseCaseProtocol
    private let saveGenerationPlaylistsUseCase: any SaveGenerationPlaylistsUseCaseProtocol
    private let openGame: @MainActor ([GameStarterViewData.GamePlaylist], GameStarterViewData.GameSettings) -> Void

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: GameStarterDependencies) {
        let provider = GameStarterViewData.Provider(dependencies.resolveProvider())
        self.viewData = GameStarterViewData(provider: provider)
        self.lastPlaylistUseCase = dependencies.resolveLastPlaylistUseCase()
        self.saveLastPlaylistUseCase = dependencies.resolveSaveLastPlaylistUseCase()
        self.gameSettingsUseCase = dependencies.resolveGameSettingsUseCase()
        self.generationPlaylistsUseCase = dependencies.resolveGenerationPlaylistsUseCase()
        self.lastGenerationPlaylistsUseCase = dependencies.resolveLastGenerationPlaylistsUseCase()
        self.saveGenerationPlaylistsUseCase = dependencies.resolveSaveGenerationPlaylistsUseCase()
        self.openGame = dependencies.resolveOpenGame()
    }

    /// The music service the user signed in with, known before its data loads.
    var provider: GameStarterViewData.Provider {
        viewData.provider
    }

    /// Text of the badge at the top: «Spotify connected».
    var connectedTitle: String {
        String(localized: "gameStarter.connected \(provider.displayName)")
    }

    /// The playlist shown in the card and played by Play: the selected one, else the last one.
    /// `nil` while it loads or when there is none.
    var selectedPlaylist: GameStarterViewData.Playlist? {
        guard state == .loaded else { return nil }
        return viewData.selectedPlaylist ?? viewData.lastPlaylist
    }

    /// `true` when the card shows a playlist chosen in the selector, not the last one played.
    var isShowingSelection: Bool {
        viewData.selectedPlaylist != nil
    }

    /// `true` once the data loaded and there is neither a selected nor a last playlist.
    var needsPlaylist: Bool {
        state == .loaded && selectedPlaylist == nil
    }

    /// The generations that each choose their own playlist, one card each. Empty while the data loads and when
    /// everyone plays with the same playlist: then the screen shows the single selected playlist card.
    var generations: [GameStarterViewData.Generation] {
        guard state == .loaded else { return [] }
        return viewData.generations
    }

    /// The playlist of `generation`: the one chosen in the selector, else the last one it played with. `nil` while
    /// it has neither.
    func playlist(for generation: GameStarterViewData.GenerationKind) -> GameStarterViewData.Playlist? {
        viewData.generationPlaylists[generation] ?? viewData.lastGenerationPlaylists[generation]
    }

    /// `true` once every playlist the game needs is chosen: the shared one, or one per generation.
    var canPlay: Bool {
        if generations.isEmpty { return selectedPlaylist != nil }
        return generations.allSatisfy { playlist(for: $0.kind) != nil }
    }

    /// The playlists Play opens the game with: the shared one, or each generation's in the order their turns go.
    /// Empty until every one is chosen.
    private var playlistsToPlay: [GameStarterViewData.GamePlaylist] {
        guard canPlay else { return [] }
        guard !generations.isEmpty else {
            return selectedPlaylist.map { [GameStarterViewData.GamePlaylist(playlist: $0, generation: nil)] } ?? []
        }
        return generations.compactMap { generation in
            playlist(for: generation.kind).map {
                GameStarterViewData.GamePlaylist(playlist: $0, generation: generation)
            }
        }
    }

    /// Title of the sheet that offers to change the music service.
    var changeProviderSheetTitle: String {
        String(localized: "gameStarter.changeProvider.title")
    }

    /// Explanation of the sheet: the service in use and that Home lets the user pick another one.
    var changeProviderSheetMessage: String {
        String(localized: "gameStarter.changeProvider.message \(provider.displayName)")
    }

    /// The badge at the top was tapped: offers to go back to Home to change the music service.
    func didTapProviderBadge() {
        wantsToReturnHome = false
        isChangeProviderSheetPresented = true
    }

    /// «Back to Home» in the sheet: closes it and asks the view to go back once it has closed.
    func didChooseReturnHome() {
        wantsToReturnHome = true
        isChangeProviderSheetPresented = false
    }

    /// «Stay here» in the sheet.
    func dismissChangeProviderSheet() {
        isChangeProviderSheetPresented = false
    }

    /// Song count under the playlist name: «312 songs», or `nil` when it is not known.
    func songCountText(for playlist: GameStarterViewData.Playlist) -> String? {
        playlist.songCount.map { String(localized: "gameStarter.selectedPlaylist.songs \($0)") }
    }

    /// Called by the playlist selector with the playlist the user chose for `generation`, or for everyone when it
    /// is `nil`.
    func selectPlaylist(_ playlist: GameStarterViewData.Playlist, for generation: GameStarterViewData.GenerationKind?) {
        if let generation {
            viewData.generationPlaylists[generation] = playlist
        } else {
            viewData.selectedPlaylist = playlist
        }
        playErrorMessage = nil
    }

    /// Play: saves the selected playlist as the last playlist (or each generation's as theirs), reads the game
    /// settings, then opens the game
    /// with the playlists, the music service and the settings. When a step fails, the game does not open and
    /// the error is shown under Play.
    func didTapPlay() async {
        let playlists = playlistsToPlay
        guard !isStartingGame, !playlists.isEmpty else { return }
        isStartingGame = true
        defer { isStartingGame = false }
        playErrorMessage = nil
        do {
            // The last playlist is everyone's: the generations' own ones are saved apart and do not replace it.
            if generations.isEmpty, let shared = playlists.first?.playlist {
                try await saveAsLastPlaylist(shared)
            } else {
                try await saveAsLastGenerationPlaylists(playlists)
            }
        } catch {
            playErrorMessage = String(localized: "gameStarter.play.saveError")
            return
        }
        do {
            let settings = try await gameSettingsUseCase.execute()
            viewData.gameSettings = settings
            openGame(playlists, settings)
        } catch {
            playErrorMessage = String(localized: "gameStarter.play.settingsError")
        }
    }

    /// Stores `playlist` as the last playlist, unless it already is.
    private func saveAsLastPlaylist(_ playlist: GameStarterViewData.Playlist) async throws {
        guard playlist != viewData.lastPlaylist else { return }
        try await saveLastPlaylistUseCase.execute(playlist: playlist)
        viewData.lastPlaylist = playlist
    }

    /// Stores the playlist of each generation in `playlists` as their last ones, unless they already are.
    private func saveAsLastGenerationPlaylists(_ playlists: [GameStarterViewData.GamePlaylist]) async throws {
        var byGeneration: [GameStarterViewData.GenerationKind: GameStarterViewData.Playlist] = [:]
        for gamePlaylist in playlists {
            if let generation = gamePlaylist.generation { byGeneration[generation.kind] = gamePlaylist.playlist }
        }
        guard byGeneration != viewData.lastGenerationPlaylists else { return }
        try await saveGenerationPlaylistsUseCase.execute(playlists: byGeneration)
        viewData.lastGenerationPlaylists = byGeneration
    }

    /// Runs every time the screen appears, so coming back from Settings shows the cards of the play mode just saved.
    func load() async {
        state = .loading
        do {
            viewData.lastPlaylist = try await lastPlaylistUseCase.execute()
            viewData.generations = try await generationPlaylistsUseCase.execute()
            viewData.lastGenerationPlaylists = try await lastGenerationPlaylistsUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "gameStarter.error \(provider.displayName)"))
        }
    }
}
