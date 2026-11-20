import Foundation

/// A generation of the `generations` play mode. Internal to TemasterData: the app only sees
/// `SettingsGenerationResponseProtocol`.
struct GenerationDAO: Sendable, Equatable, SettingsGenerationResponseProtocol {
    let generation: SettingsGeneration
    let titleKey: String
    let firstYear: Int?
    let lastYear: Int?

    /// The name's key follows `generation.<generation>`. The years are those of its name: up to 1984, 1985-2004
    /// and from 2005.
    init(generation: SettingsGeneration) {
        self.generation = generation
        self.titleKey = "generation.\(generation.rawValue)"
        switch generation {
        case .vinyl:
            (firstYear, lastYear) = (nil, 1984)
        case .cassette:
            (firstYear, lastYear) = (1985, 2004)
        case .streaming:
            (firstYear, lastYear) = (2005, nil)
        }
    }
}
