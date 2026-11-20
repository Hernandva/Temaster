import Foundation
@testable import TemasterData
import Testing

private struct FakeLastPlaylistRequest: LastPlaylistRequestProtocol {
    let provider: MusicProvider
}

struct LastPlaylistRepositoryTests {
    private static let playlist = LastPlaylistItemDAO(
        id: "pl.123",
        name: "Hitster España",
        songCount: 312,
        coverURLs: [URL(string: "https://example.com/cover.jpg")].compactMap { $0 }
    )

    /// A repository on its own empty `UserDefaults` suite, so tests never share data.
    private static func makeRepository() -> LastPlaylistRepository {
        let suiteName = "LastPlaylistRepositoryTests.\(UUID().uuidString)"
        return LastPlaylistRepository(storage: LastPlaylistUserDefaultsStorage(suiteName: suiteName))
    }

    @Test func returnsNoPlaylistWhenNoneWasSaved() async throws {
        let repository = Self.makeRepository()

        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.provider == .appleMusic)
        #expect(response.lastPlaylist == nil)
    }

    @Test func returnsTheSavedPlaylistOfTheProvider() async throws {
        let repository = Self.makeRepository()

        try await repository.saveLastPlaylist(Self.playlist, for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.lastPlaylist?.id == "pl.123")
        #expect(response.lastPlaylist?.name == "Hitster España")
        #expect(response.lastPlaylist?.songCount == 312)
        #expect(response.lastPlaylist?.coverURLs == Self.playlist.coverURLs)
    }

    @Test func keepsEachProviderPlaylistApart() async throws {
        let repository = Self.makeRepository()

        try await repository.saveLastPlaylist(Self.playlist, for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.lastPlaylist == nil)
    }

    @Test func replacesThePreviousPlaylist() async throws {
        let repository = Self.makeRepository()
        let newer = LastPlaylistItemDAO(id: "pl.456", name: "Hitster 80s", songCount: 95, coverURLs: [])

        try await repository.saveLastPlaylist(Self.playlist, for: .spotify)
        try await repository.saveLastPlaylist(newer, for: .spotify)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.lastPlaylist?.id == "pl.456")
    }

    @Test func returnsNoGenerationPlaylistsWhenNoneWereSaved() async throws {
        let response = try await Self.makeRepository().fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.generationPlaylists.isEmpty)
    }

    @Test func returnsTheSavedPlaylistOfEachGeneration() async throws {
        let repository = Self.makeRepository()
        let cassette = LastPlaylistItemDAO(id: "pl.456", name: "Hitster 90s", songCount: nil, coverURLs: [])

        try await repository.saveGenerationPlaylists([.vinyl: Self.playlist, .cassette: cassette], for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.generationPlaylists[.vinyl]?.id == "pl.123")
        #expect(response.generationPlaylists[.vinyl]?.songCount == 312)
        #expect(response.generationPlaylists[.cassette]?.name == "Hitster 90s")
        #expect(response.generationPlaylists[.streaming] == nil)
    }

    @Test func keepsTheGenerationPlaylistsApartFromTheLastPlaylist() async throws {
        let repository = Self.makeRepository()
        let vinyl = LastPlaylistItemDAO(id: "pl.789", name: "Hitster 70s", songCount: 80, coverURLs: [])

        try await repository.saveLastPlaylist(Self.playlist, for: .spotify)
        try await repository.saveGenerationPlaylists([.vinyl: vinyl], for: .spotify)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.lastPlaylist?.id == "pl.123")
        #expect(response.generationPlaylists[.vinyl]?.id == "pl.789")
    }

    @Test func keepsEachProviderGenerationPlaylistsApart() async throws {
        let repository = Self.makeRepository()

        try await repository.saveGenerationPlaylists([.vinyl: Self.playlist], for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.generationPlaylists.isEmpty)
    }

    @Test func replacesThePreviousGenerationPlaylists() async throws {
        let repository = Self.makeRepository()
        let streaming = LastPlaylistItemDAO(id: "pl.456", name: "Hitster 2010s", songCount: 95, coverURLs: [])

        try await repository.saveGenerationPlaylists([.vinyl: Self.playlist], for: .spotify)
        try await repository.saveGenerationPlaylists([.streaming: streaming], for: .spotify)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.generationPlaylists[.vinyl] == nil)
        #expect(response.generationPlaylists[.streaming]?.id == "pl.456")
    }

    @Test func returnsTheSavedPlaylistOfEachCustomGeneration() async throws {
        let repository = Self.makeRepository()
        let other = LastPlaylistItemDAO(id: "pl.456", name: "Hitster 2010s", songCount: nil, coverURLs: [])

        try await repository.saveCustomGenerationPlaylists(["gen.a": Self.playlist, "gen.b": other], for: .spotify)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.customGenerationPlaylists["gen.a"]?.id == "pl.123")
        #expect(response.customGenerationPlaylists["gen.b"]?.name == "Hitster 2010s")
        #expect(response.customGenerationPlaylists["gen.c"] == nil)
    }

    @Test func keepsTheCustomGenerationPlaylistsApartFromTheGenerationOnes() async throws {
        let repository = Self.makeRepository()
        let custom = LastPlaylistItemDAO(id: "pl.789", name: "Mis 90", songCount: 40, coverURLs: [])

        try await repository.saveGenerationPlaylists([.vinyl: Self.playlist], for: .spotify)
        try await repository.saveCustomGenerationPlaylists(["gen.a": custom], for: .spotify)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .spotify))

        #expect(response.generationPlaylists[.vinyl]?.id == "pl.123")
        #expect(response.customGenerationPlaylists["gen.a"]?.id == "pl.789")
    }

    @Test func replacesThePreviousCustomGenerationPlaylists() async throws {
        let repository = Self.makeRepository()

        try await repository.saveCustomGenerationPlaylists(["gen.a": Self.playlist], for: .appleMusic)
        try await repository.saveCustomGenerationPlaylists(["gen.b": Self.playlist], for: .appleMusic)
        let response = try await repository.fetch(FakeLastPlaylistRequest(provider: .appleMusic))

        #expect(response.customGenerationPlaylists["gen.a"] == nil)
        #expect(response.customGenerationPlaylists["gen.b"]?.id == "pl.123")
        #expect(response.generationPlaylists.isEmpty)
    }
}
