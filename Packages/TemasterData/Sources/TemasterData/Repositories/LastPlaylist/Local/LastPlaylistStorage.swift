import Foundation

/// Local storage of the Provider repository: one last playlist per music service. Internal.
protocol LastPlaylistStorageProtocol: Sendable {
    /// The stored playlist of `provider`, or `nil` when there is none or it cannot be read.
    func lastPlaylist(for provider: MusicProvider) -> LastPlaylistItemDAO?
    func saveLastPlaylist(_ playlist: LastPlaylistItemDAO, for provider: MusicProvider) throws
    /// The stored playlists of each generation of `provider`; empty when there are none or they cannot be read.
    func generationPlaylists(for provider: MusicProvider) -> [SettingsGeneration: LastPlaylistItemDAO]
    func saveGenerationPlaylists(
        _ playlists: [SettingsGeneration: LastPlaylistItemDAO],
        for provider: MusicProvider
    ) throws
}

/// Keeps each provider's last playlist, and its generations' playlists, as JSON in `UserDefaults`, under their own
/// keys.
struct LastPlaylistUserDefaultsStorage: LastPlaylistStorageProtocol {
    private static let keyPrefix = "temasterData.lastPlaylist."
    private static let generationsKeyPrefix = "temasterData.generationPlaylists."

    /// `UserDefaults` is not `Sendable`, so the storage keeps the suite name and opens it on each access.
    /// `nil` uses the standard defaults.
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    func lastPlaylist(for provider: MusicProvider) -> LastPlaylistItemDAO? {
        guard let data = defaults.data(forKey: Self.key(for: provider)) else { return nil }
        return try? JSONDecoder().decode(LastPlaylistItemDAO.self, from: data)
    }

    func saveLastPlaylist(_ playlist: LastPlaylistItemDAO, for provider: MusicProvider) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(playlist)
        } catch {
            throw LastPlaylistError.storageFailed
        }
        defaults.set(data, forKey: Self.key(for: provider))
    }

    /// Stored as a JSON object keyed by the generations' raw values; a key no generation has any more is skipped.
    func generationPlaylists(for provider: MusicProvider) -> [SettingsGeneration: LastPlaylistItemDAO] {
        guard let data = defaults.data(forKey: Self.generationsKey(for: provider)),
              let stored = try? JSONDecoder().decode([String: LastPlaylistItemDAO].self, from: data) else { return [:] }
        return stored.reduce(into: [:]) { playlists, entry in
            guard let generation = SettingsGeneration(rawValue: entry.key) else { return }
            playlists[generation] = entry.value
        }
    }

    func saveGenerationPlaylists(
        _ playlists: [SettingsGeneration: LastPlaylistItemDAO],
        for provider: MusicProvider
    ) throws {
        let stored = Dictionary(uniqueKeysWithValues: playlists.map { ($0.key.rawValue, $0.value) })
        let data: Data
        do {
            data = try JSONEncoder().encode(stored)
        } catch {
            throw LastPlaylistError.storageFailed
        }
        defaults.set(data, forKey: Self.generationsKey(for: provider))
    }

    /// Stable key per provider: it must not change between versions, or saved playlists are lost.
    static func key(for provider: MusicProvider) -> String {
        switch provider {
        case .spotify: keyPrefix + "spotify"
        case .appleMusic: keyPrefix + "appleMusic"
        }
    }

    /// Stable key of the generations' playlists per provider: it must not change between versions either.
    static func generationsKey(for provider: MusicProvider) -> String {
        switch provider {
        case .spotify: generationsKeyPrefix + "spotify"
        case .appleMusic: generationsKeyPrefix + "appleMusic"
        }
    }
}
