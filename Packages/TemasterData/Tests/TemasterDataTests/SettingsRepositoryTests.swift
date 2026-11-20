import Foundation
@testable import TemasterData
import Testing

private struct FakeSettingsRequest: SettingsRequestProtocol {
    let provider: MusicProvider
}

struct SettingsRepositoryTests {
    private static let custom = GameSettingsDAO(
        playbackMode: .fullSong,
        clipSeconds: 45,
        clipStart: .beginning,
        gameMode: .bingo,
        bingoLevel: .expert,
        playMode: .generations,
        customGenerations: [
            CustomGenerationDAO(
                id: "90s",
                name: "Los noventa",
                symbolName: "guitars.fill",
                color: .orange,
                firstYear: 1990,
                lastYear: 1999
            ),
            CustomGenerationDAO(id: "now", name: "Lo último", symbolName: "sparkles", firstYear: 2020, lastYear: nil)
        ]
    )

    /// A repository on its own empty `UserDefaults` suite, so tests never share data.
    private static func makeRepository(suiteName: String = "SettingsRepositoryTests.\(UUID().uuidString)")
        -> SettingsRepository {
        SettingsRepository(storage: SettingsUserDefaultsStorage(suiteName: suiteName))
    }

    @Test func returnsTheDefaultsWhenNoneWereSaved() async throws {
        let response = try await Self.makeRepository().fetch(FakeSettingsRequest(provider: .appleMusic))

        #expect(GameSettingsDAO(response) == GameSettingsDAO.defaults)
    }

    @Test func returnsTheSavedSettings() async throws {
        let repository = Self.makeRepository()

        try await repository.saveSettings(Self.custom, for: .appleMusic)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .appleMusic))

        #expect(GameSettingsDAO(response) == Self.custom)
    }

    @Test func keepsEachProviderSettingsApart() async throws {
        let repository = Self.makeRepository()

        try await repository.saveSettings(Self.custom, for: .appleMusic)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(GameSettingsDAO(response) == GameSettingsDAO.defaults)
    }

    @Test func fillsMissingFieldsWithTheDefaults() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"gameMode":"bingo","clipSeconds":30}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.gameMode == .bingo)
        #expect(response.clipSeconds == 30)
        #expect(response.playbackMode == GameSettingsDAO.defaults.playbackMode)
        #expect(response.bingoLevel == GameSettingsDAO.defaults.bingoLevel)
    }

    @Test func ignoresTheRemovedBingoCategoriesField() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"bingoLevel":"expert","disabledBingoCategories":{"expert":["pink"]}}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.bingoLevel == .expert)
    }

    @Test func offersEveryBingoLevelInOrder() async {
        let levels = await Self.makeRepository().bingoLevels()

        #expect(levels.map(\.level) == SettingsBingoLevel.allCases)
    }

    @Test func everyBingoLevelHasTheFiveCategoriesWithItsOwnNames() async {
        let levels = await Self.makeRepository().bingoLevels()

        for level in levels {
            #expect(level.titleKey == "bingo.level.\(level.level.rawValue)")
            #expect(level.categories.map(\.category) == SettingsBingoCategory.allCases)
            #expect(level.categories.map(\.titleKey) == SettingsBingoCategory.allCases.map {
                "bingo.category.\($0.rawValue).\(level.level.rawValue)"
            })
        }
    }

    @Test func readsAnUnknownBingoLevelAsTheDefaultAndKeepsTheRest() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"bingoLevel":"master","gameMode":"bingo","clipSeconds":45}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.bingoLevel == GameSettingsDAO.defaults.bingoLevel)
        #expect(response.gameMode == .bingo)
        #expect(response.clipSeconds == 45)
    }

    @Test func playsIndividuallyByDefault() {
        #expect(GameSettingsDAO.defaults.playMode == .individual)
    }

    @Test func readsAMissingOrUnknownPlayModeAsIndividualAndKeepsTheRest() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"playMode":"teams","gameMode":"bingo"}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.playMode == .individual)
        #expect(response.gameMode == .bingo)
    }

    @Test func offersTheThreeGenerationsInOrderWithTheirNames() async {
        let generations = await Self.makeRepository().generations()

        #expect(generations.map(\.generation) == [.vinyl, .cassette, .streaming])
        #expect(generations.map(\.titleKey) == ["generation.vinyl", "generation.cassette", "generation.streaming"])
    }

    @Test func givesEachGenerationTheYearsOfItsSongs() async {
        let generations = await Self.makeRepository().generations()

        #expect(generations.map(\.firstYear) == [nil, 1985, 2005])
        #expect(generations.map(\.lastYear) == [1984, 2004, nil])
    }

    @Test func ignoresTheRemovedSharedPlaylistField() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"playMode":"generations","sharedPlaylist":true}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.playMode == .generations)
    }

    @Test func keepsTheCustomPlayMode() async throws {
        let repository = Self.makeRepository()
        let custom = GameSettingsDAO(
            playbackMode: .clip,
            clipSeconds: 30,
            clipStart: .random,
            gameMode: .classic,
            bingoLevel: .beginner,
            playMode: .custom
        )

        try await repository.saveSettings(custom, for: .spotify)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.playMode == .custom)
    }

    @Test func startsWithNoCustomGenerations() {
        #expect(GameSettingsDAO.defaults.customGenerations.isEmpty)
    }

    @Test func dropsUnreadableCustomGenerationsAndKeepsTheRest() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let stored = Data(#"{"playMode":"custom","customGenerations":[{"name":"Sin años"}]}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.customGenerations.isEmpty)
        #expect(response.playMode == .custom)
    }

    @Test func readsACustomGenerationWithoutColorAsTheDefaultColor() async throws {
        let suiteName = "SettingsRepositoryTests.\(UUID().uuidString)"
        let generation = #"{"id":"a","name":"Los noventa","symbolName":"music.note","firstYear":1990}"#
        let stored = Data(#"{"playMode":"custom","customGenerations":[\#(generation)]}"#.utf8)
        UserDefaults(suiteName: suiteName)?.set(stored, forKey: SettingsUserDefaultsStorage.key(for: .spotify))

        let repository = Self.makeRepository(suiteName: suiteName)
        let response = try await repository.fetch(FakeSettingsRequest(provider: .spotify))

        #expect(response.customGenerations.map(\.color) == [CustomGenerationDAO.defaultColor])
        #expect(response.customGenerations.map(\.lastYear) == [nil])
    }
}
