import SwiftUI

/// The look of the three generations of the «Generations» play mode: each one's fixed color and icon. The colors
/// are light, so icons on them are always `bg-night`, never white.
///
/// Only the look lives here. Which generations exist and what each is called come from the app's data (the
/// Settings repository), and components that show a generation's name receive it already localised.
public enum DSGeneration: Int, CaseIterable, Identifiable, Sendable {
    /// Vinyl classics.
    case vinyl
    /// Cassette and CD.
    case cassette
    /// Streaming songs.
    case streaming

    public var id: Int { rawValue }

    public var color: Color {
        switch self {
        case .vinyl: DSPalette.bingoPink
        case .cassette: DSPalette.bingoGreen
        case .streaming: DSPalette.bingoYellow
        }
    }

    /// SF Symbol of the generation's music format.
    public var symbolName: String {
        switch self {
        case .vinyl: "record.circle.fill"
        case .cassette: "recordingtape"
        case .streaming: "play.fill"
        }
    }

    /// Icons on `color`.
    public var ink: Color { DSColor.background }
}

/// Settings row of a generation: its icon on its color and its name, already localised. It goes inside a
/// `DSListGroup`.
public struct DSGenerationRow: View {
    private static let swatch: CGFloat = 28
    private let color: Color
    private let symbolName: String
    private let title: String
    private let subtitle: String?

    public init(generation: DSGeneration, title: String) {
        self.init(symbolName: generation.symbolName, color: generation.color, title: title)
    }

    /// A generation the user created: its own icon on `color` (a light one, so the icon is `bg-night`), its name
    /// and, e.g., its years in `subtitle`. Texts are passed localised.
    public init(symbolName: String, color: Color = DSPalette.bingoCyan, title: String, subtitle: String? = nil) {
        self.color = color
        self.symbolName = symbolName
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space3) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                }
                .overlay {
                    Image(systemName: symbolName)
                        .font(DSFont.footnote.weight(.semibold))
                        .foregroundStyle(DSColor.background)
                }
                .frame(width: Self.swatch, height: Self.swatch)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.space1) {
                Text(title)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(DSTypeScale.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DSSpacing.space4)
        .padding(.vertical, subtitle == nil ? 0 : DSSpacing.space3)
        .frame(minHeight: DSListRow.minHeight)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DSListGroup {
        DSGenerationRow(generation: .vinyl, title: "Clásicos en vinilo (Hasta 1984)")
        DSGenerationRow(generation: .cassette, title: "Casete y CD (1985-2004)")
        DSGenerationRow(generation: .streaming, title: "Canciones en streaming (Desde 2005)")
        DSGenerationRow(symbolName: "guitars.fill", title: "Los noventa", subtitle: "1990 – 1999")
    }
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
