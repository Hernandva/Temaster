import Foundation

/// The song a provider player started. Internal to TemasterData: the app only sees PlayerResponseProtocol.
struct PlayerResponseDAO: Sendable, Equatable, PlayerResponseProtocol {
    let provider: MusicProvider
    let songID: String
    let duration: TimeInterval?
}
