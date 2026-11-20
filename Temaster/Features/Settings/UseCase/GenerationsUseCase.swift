import Foundation
import TemasterData

protocol GenerationsUseCaseProtocol: Sendable {
    /// Returns only the generations of the «Generations» play mode, names already localised.
    /// The view model adds them to its `SettingsViewData`.
    func execute() async -> [SettingsViewData.Generation]
}

/// Reads the generations through the Settings repository public API.
struct GenerationsUseCase: GenerationsUseCaseProtocol {
    private let repository: any SettingsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    @MainActor
    init(dependencies: SettingsDependencies) {
        self.repository = dependencies.resolveRepository()
    }

    func execute() async -> [SettingsViewData.Generation] {
        await repository.generations().map(Self.generation)
    }
}

private extension GenerationsUseCase {
    /// Maps a generation of the repository into the data the view model adds to its ViewData.
    static func generation(_ response: any SettingsGenerationResponseProtocol) -> SettingsViewData.Generation {
        SettingsViewData.Generation(
            kind: kind(response.generation),
            title: String(localized: String.LocalizationValue(response.titleKey))
        )
    }

    static func kind(_ generation: SettingsGeneration) -> SettingsViewData.GenerationKind {
        switch generation {
        case .vinyl: .vinyl
        case .cassette: .cassette
        case .streaming: .streaming
        }
    }
}
