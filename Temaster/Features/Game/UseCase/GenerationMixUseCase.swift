import Foundation

protocol GenerationMixUseCaseProtocol: Sendable {
    /// Picks the songs `generation` plays from its own playlist, by release year: 70 % of its own generation, 20 % of
    /// the nearest one and 10 % of the farthest one, as many as the playlist allows. Returns the songs unchanged when
    /// none of them has a release year in any generation.
    func execute(
        songs: [GameViewData.Song],
        generation: GameViewData.Generation,
        generations: [GameViewData.Generation]
    ) -> [GameViewData.Song]
}

/// Mixes a generation's playlist so most of its songs are of its time. The songs are split into one group per
/// generation by their release year; songs without a year, or out of every generation, are left out.
struct GenerationMixUseCase: GenerationMixUseCaseProtocol {
    /// Share of the songs, in percent, of the generation itself, the nearest one and the farthest one.
    static let shares = [70, 20, 10]

    /// Receives only the container. It needs nothing from it: the mix only reads the songs it is given.
    @MainActor
    init(dependencies: GameDependencies) {}

    func execute(
        songs: [GameViewData.Song],
        generation: GameViewData.Generation,
        generations: [GameViewData.Generation]
    ) -> [GameViewData.Song] {
        let groups = Self.order(of: generation, in: generations).map { group in
            songs.filter { song in song.releaseYear.map(group.contains(year:)) ?? false }
        }
        // Without release years there is nothing to mix by: the generation plays the whole playlist.
        guard groups.contains(where: { !$0.isEmpty }) else { return songs }
        let counts = Self.counts(available: groups.map(\.count), shares: Array(Self.shares.prefix(groups.count)))
        return zip(groups, counts).flatMap { group, count in group.shuffled().prefix(count) }
    }

    /// The generation itself first, then the others from the nearest to the farthest. Between two as near, the
    /// later one goes first: the cassette generation's nearest is streaming.
    static func order(
        of generation: GameViewData.Generation,
        in generations: [GameViewData.Generation]
    ) -> [GameViewData.Generation] {
        guard let own = generations.firstIndex(of: generation) else { return [generation] }
        let others = generations.indices.filter { $0 != own }.sorted { lhs, rhs in
            let lhsDistance = abs(lhs - own)
            let rhsDistance = abs(rhs - own)
            return lhsDistance != rhsDistance ? lhsDistance < rhsDistance : lhs > rhs
        }
        return [generation] + others.map { generations[$0] }
    }

    /// How many songs to take of each group: as many as there can be while keeping `shares` between them. A group
    /// with no songs gives its share to the others, so the game does not end up empty.
    static func counts(available: [Int], shares: [Int]) -> [Int] {
        let used = zip(available, shares).map { count, share in count > 0 ? share : 0 }
        let totalShare = used.reduce(0, +)
        guard totalShare > 0 else { return used.map { _ in 0 } }
        let total = zip(available, used)
            .filter { $0.1 > 0 }
            .map { count, share in count * totalShare / share }
            .min() ?? 0
        var counts = used.map { total * $0 / totalShare }
        var left = total - counts.reduce(0, +)
        // Rounding down leaves a few songs: they go to the groups that lost the most, while they have songs.
        let byRemainder = used.indices.sorted { total * used[$0] % totalShare > total * used[$1] % totalShare }
        for index in byRemainder where left > 0 && used[index] > 0 && counts[index] < available[index] {
            counts[index] += 1
            left -= 1
        }
        return counts
    }
}
