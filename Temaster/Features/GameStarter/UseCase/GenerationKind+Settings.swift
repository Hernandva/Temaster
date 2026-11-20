import Foundation
import TemasterData

/// Converts the generations of GameStarter to and from the Settings repository's, for the use cases that read or
/// store them. The view and the view model only see `GameStarterViewData.GenerationKind`.
extension GameStarterViewData.GenerationKind {
    init(_ generation: SettingsGeneration) {
        switch generation {
        case .vinyl: self = .vinyl
        case .cassette: self = .cassette
        case .streaming: self = .streaming
        }
    }

    var settingsGeneration: SettingsGeneration {
        switch self {
        case .vinyl: .vinyl
        case .cassette: .cassette
        case .streaming: .streaming
        }
    }
}
