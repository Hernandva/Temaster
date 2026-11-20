import Foundation

/// A generation of the `generations` play mode. Internal to TemasterData: the app only sees
/// `SettingsGenerationResponseProtocol`.
struct GenerationDAO: Sendable, Equatable, SettingsGenerationResponseProtocol {
    let generation: SettingsGeneration
    let titleKey: String

    /// The name's key follows `generation.<generation>`.
    init(generation: SettingsGeneration) {
        self.generation = generation
        self.titleKey = "generation.\(generation.rawValue)"
    }
}
