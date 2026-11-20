import TemasterUI
import SwiftUI

/// The game's state in the design system's terms, shared by the iPhone's `GameView` and the TV's
/// `GameExternalDisplayView` so both show the same round.
extension GameViewModel {
    /// Look of the round's Bingo category. `nil` in the classic mode.
    var category: DSBingoCategory? {
        viewData.bingoCategory.map { DSBingoCategory($0.color) }
    }

    /// Name of the round's Bingo category in the level, from the Settings repository. `nil` in the classic mode.
    var categoryTitle: String? {
        viewData.bingoCategory?.title
    }

    /// The generation whose turn it is, shown under the vinyl. `nil` when everyone plays with the same playlist.
    var generation: DSVinyl.Generation? {
        guard let generation = currentPlaylist?.generation else { return nil }
        switch generation.look {
        case .vinyl: return DSVinyl.Generation(.vinyl, title: generation.title)
        case .cassette: return DSVinyl.Generation(.cassette, title: generation.title)
        case .streaming: return DSVinyl.Generation(.streaming, title: generation.title)
        case .custom(let symbolName, let color):
            return DSVinyl.Generation(
                symbolName: symbolName,
                title: generation.title,
                color: DSBingoCategory(color).color
            )
        }
    }

    /// Style of the mode chip at the top: the round's category in the Bingo mode.
    var badgeStyle: DSChip.Style {
        viewData.settings.mode == .bingo ? .bingo(category) : .standard
    }

    var vinylPhase: DSVinyl.Phase {
        if viewData.isRevealed {
            // The song keeps sounding after Reveal; when it ends the game pauses, and so does the disc.
            return .revealed(cover: currentSong?.largeCover ?? currentSong?.cover, isPaused: viewData.isPaused)
        }
        return viewData.isPaused ? .paused : .playing
    }

    /// The album, under the revealed song's title.
    var revealedDetails: [DSSongRevealCard.Detail] {
        currentSong?.album.map { [.init(String(localized: "game.reveal.album"), value: $0)] } ?? []
    }

    /// Icon after the artist: solo artist or group, once MusicBrainz answers.
    var revealedArtistKind: DSSongRevealCard.ArtistKind? {
        switch viewData.artist?.kind {
        case .solo: .init(.solo, label: String(localized: "game.reveal.artist.solo"))
        case .group: .init(.group, label: String(localized: "game.reveal.artist.group"))
        case nil: nil
        }
    }

    /// Flags after the artist, with each country's name in the user's language for VoiceOver.
    var revealedArtistCountries: [DSSongRevealCard.Country] {
        (viewData.artist?.countryCodes ?? []).map { code in
            .init(regionCode: code, label: Locale.current.localizedString(forRegionCode: code) ?? code)
        }
    }

    /// The song's length, under the year.
    var revealedDuration: DSSongRevealCard.Detail? {
        revealedDurationText.map { .init(String(localized: "game.reveal.duration"), value: $0) }
    }
}

private extension DSBingoCategory {
    init(_ color: GameViewData.BingoColor) {
        switch color {
        case .pink: self = .pink
        case .yellow: self = .yellow
        case .cyan: self = .cyan
        case .green: self = .green
        case .orange: self = .orange
        }
    }
}
