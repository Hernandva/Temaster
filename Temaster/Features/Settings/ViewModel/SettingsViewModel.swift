import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData: SettingsViewData
    /// Shown at the bottom when a change could not be saved.
    private(set) var saveErrorMessage: String?
    /// Whether the custom generation sheet («New generation» or «Edit generation») is open.
    var isCustomGenerationSheetOpen = false
    /// What the user is typing in the custom generation sheet.
    var customGenerationDraft = SettingsViewData.CustomGenerationDraft()
    /// The generation the sheet edits, or `nil` when it creates a new one.
    private(set) var editingCustomGenerationID: String?

    private let settingsUseCase: any SettingsUseCaseProtocol
    private let bingoLevelsUseCase: any BingoLevelsUseCaseProtocol
    private let generationsUseCase: any GenerationsUseCaseProtocol
    private let saveSettingsUseCase: any SaveSettingsUseCaseProtocol
    private let signOut: @MainActor () -> Void
    /// The last save, so each one waits for the previous and the newest settings are written last.
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: SettingsDependencies) {
        self.viewData = SettingsViewData(provider: SettingsViewData.Provider(dependencies.resolveProvider()))
        self.settingsUseCase = dependencies.resolveSettingsUseCase()
        self.bingoLevelsUseCase = dependencies.resolveBingoLevelsUseCase()
        self.generationsUseCase = dependencies.resolveGenerationsUseCase()
        self.saveSettingsUseCase = dependencies.resolveSaveSettingsUseCase()
        self.signOut = dependencies.resolveSignOut()
    }

    // MARK: Settings, bound to the controls. Each change is saved right away.

    var playback: SettingsViewData.Playback {
        get { viewData.game?.playback ?? .clip }
        set { update { $0.playback = newValue } }
    }

    /// Length of a clip, as the slider needs it.
    var clipSeconds: Double {
        get { Double(viewData.game?.clipSeconds ?? SettingsViewData.Game.clipSecondsRange.lowerBound) }
        set { update { $0.clipSeconds = Int(newValue.rounded()) } }
    }

    var clipStart: SettingsViewData.ClipStart {
        get { viewData.game?.clipStart ?? .random }
        set { update { $0.clipStart = newValue } }
    }

    var gameMode: SettingsViewData.GameMode {
        get { viewData.game?.mode ?? .classic }
        set { update { $0.mode = newValue } }
    }

    /// Identifier of the selected Bingo level, as the segmented control needs it.
    var bingoLevel: String {
        get { viewData.game?.bingoLevel ?? "" }
        set { update { $0.bingoLevel = newValue } }
    }

    var playMode: SettingsViewData.PlayMode {
        get { viewData.game?.playMode ?? .individual }
        set { update { $0.playMode = newValue } }
    }

    /// The three generations from the repository. They all always play.
    var generations: [SettingsViewData.Generation] {
        viewData.generations
    }

    /// Generations the user created for the `custom` play mode.
    var customGenerations: [SettingsViewData.CustomGeneration] {
        viewData.game?.customGenerations ?? []
    }

    /// The Bingo levels from the repository, for the level selector.
    var bingoLevels: [SettingsViewData.BingoLevel] {
        viewData.bingoLevels
    }

    /// Categories of the selected level, with their names in it.
    var bingoCategories: [SettingsViewData.BingoCategory] {
        viewData.bingoLevels.first { $0.id == bingoLevel }?.categories ?? []
    }

    // MARK: Texts

    /// Value next to «Length»: «20 s».
    var clipSecondsText: String {
        Self.secondsText(Int(clipSeconds))
    }

    static func secondsText(_ seconds: Int) -> String {
        String(localized: "settings.playback.seconds \(seconds)")
    }

    /// What each round will play, under the Playback section.
    var playbackFooter: String {
        let seconds = Int(clipSeconds)
        switch (playback, clipStart) {
        case (.fullSong, _): return String(localized: "settings.playback.footer.fullSong")
        case (.clip, .beginning): return String(localized: "settings.playback.footer.clip.beginning \(seconds)")
        case (.clip, .random): return String(localized: "settings.playback.footer.clip.random \(seconds)")
        }
    }

    /// How the selected play mode splits the players, under the Players section.
    var playModeFooter: String {
        switch playMode {
        case .individual: String(localized: "settings.players.footer.individual")
        case .generations: String(localized: "settings.players.footer.generations")
        case .custom: String(localized: "settings.players.footer.custom")
        }
    }

    /// Years of a custom generation in its row: «1990 – 1999», «Pasado – 1999» or «1990 – Actualidad».
    static func yearsText(_ generation: SettingsViewData.CustomGeneration) -> String {
        let first = generation.firstYear.map(String.init) ?? String(localized: "settings.players.custom.past")
        let last = generation.lastYear.map(String.init) ?? String(localized: "settings.players.custom.today")
        return String(localized: "settings.players.custom.years \(first) \(last)")
    }

    /// «Save» is enabled only with a name and at least one year, every typed year valid.
    var canSaveCustomGeneration: Bool {
        validCustomGeneration != nil
    }

    /// Under the years when a typed one is not valid, or the first is after the last; `nil` otherwise, also while
    /// both are empty (the hint already asks for one).
    var customGenerationYearsError: String? {
        let first = YearInput(customGenerationDraft.firstYear)
        let last = YearInput(customGenerationDraft.lastYear)
        guard first != .empty || last != .empty, validYears == nil else { return nil }
        let earliest = String(SettingsViewData.CustomGeneration.firstAllowedYear)
        let latest = String(Self.currentYear)
        return String(localized: "settings.players.custom.sheet.yearsError \(earliest) \(latest)")
    }

    /// Name of the music service in the Account section.
    var providerName: String {
        viewData.provider.displayName
    }

    // MARK: Actions

    /// «Sign out»: goes back to Home.
    func didTapSignOut() {
        signOut()
    }

    /// «Add new» in the custom generations: opens the «New generation» sheet with an empty form.
    func didTapAddCustomGeneration() {
        editingCustomGenerationID = nil
        customGenerationDraft = SettingsViewData.CustomGenerationDraft()
        isCustomGenerationSheetOpen = true
    }

    /// Edit button of a custom generation: opens the sheet with its data.
    func didTapEditCustomGeneration(_ generation: SettingsViewData.CustomGeneration) {
        editingCustomGenerationID = generation.id
        customGenerationDraft = SettingsViewData.CustomGenerationDraft(
            name: generation.name,
            symbolName: generation.symbolName,
            color: generation.color,
            firstYear: generation.firstYear.map(String.init) ?? "",
            lastYear: generation.lastYear.map(String.init) ?? ""
        )
        isCustomGenerationSheetOpen = true
    }

    /// Delete button of a custom generation: takes it off the list and off the saved settings.
    func didTapDeleteCustomGeneration(_ generation: SettingsViewData.CustomGeneration) {
        update { $0.customGenerations.removeAll { $0.id == generation.id } }
    }

    /// «Save» in the sheet: replaces the edited generation in its place, or adds a new one at the end, saves it and
    /// closes the sheet. It does nothing while the form is not valid.
    func didTapSaveCustomGeneration() {
        guard let generation = validCustomGeneration else { return }
        update { game in
            if let index = game.customGenerations.firstIndex(where: { $0.id == generation.id }) {
                game.customGenerations[index] = generation
            } else {
                game.customGenerations.append(generation)
            }
        }
        isCustomGenerationSheetOpen = false
    }

    /// Title of the sheet: «New generation» or «Edit generation».
    var customGenerationSheetTitle: String {
        editingCustomGenerationID == nil
            ? String(localized: "settings.players.custom.sheet.title")
            : String(localized: "settings.players.custom.sheet.editTitle")
    }

    func load() async {
        state = .loading
        viewData.bingoLevels = await bingoLevelsUseCase.execute()
        viewData.generations = await generationsUseCase.execute()
        do {
            viewData.game = try await settingsUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(String(localized: "settings.error"))
        }
    }
}

private extension SettingsViewModel {
    nonisolated static var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// A year field as typed.
    enum YearInput: Equatable {
        /// Left empty: the past for the first year, today for the last one.
        case empty
        case year(Int)
        /// Not a number between 1900 and this year.
        case invalid

        init(_ text: String) {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            let allowed = SettingsViewData.CustomGeneration.firstAllowedYear...SettingsViewModel.currentYear
            if trimmed.isEmpty {
                self = .empty
            } else if let year = Int(trimmed), allowed.contains(year) {
                self = .year(year)
            } else {
                self = .invalid
            }
        }

        var value: Int? {
            if case .year(let year) = self { return year }
            return nil
        }
    }

    /// The typed years when at least one is set, each between 1900 and this year, and the first not after the last.
    /// An empty one is `nil`: any year before the last one, or any year after the first one.
    var validYears: (first: Int?, last: Int?)? {
        let first = YearInput(customGenerationDraft.firstYear)
        let last = YearInput(customGenerationDraft.lastYear)
        guard first != .invalid, last != .invalid, first != .empty || last != .empty else { return nil }
        if let firstYear = first.value, let lastYear = last.value, firstYear > lastYear { return nil }
        return (first.value, last.value)
    }

    /// The generation the form describes, or `nil` while it has no name or its years are not valid.
    var validCustomGeneration: SettingsViewData.CustomGeneration? {
        let name = customGenerationDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let years = validYears else { return nil }
        return SettingsViewData.CustomGeneration(
            // An edited generation keeps its id, so it stays in its place in the list.
            id: editingCustomGenerationID ?? UUID().uuidString,
            name: name,
            symbolName: customGenerationDraft.symbolName,
            color: customGenerationDraft.color,
            firstYear: years.first,
            lastYear: years.last
        )
    }

    /// Applies `change` to the loaded settings and saves them when they changed.
    func update(_ change: (inout SettingsViewData.Game) -> Void) {
        guard var game = viewData.game else { return }
        change(&game)
        guard game != viewData.game else { return }
        viewData.game = game
        save(game)
    }

    func save(_ game: SettingsViewData.Game) {
        let previous = saveTask
        saveTask = Task { [saveSettingsUseCase] in
            await previous?.value
            do {
                try await saveSettingsUseCase.execute(game: game)
                saveErrorMessage = nil
            } catch {
                saveErrorMessage = String(localized: "settings.saveError")
            }
        }
    }
}
