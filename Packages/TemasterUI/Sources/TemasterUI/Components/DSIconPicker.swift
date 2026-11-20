import SwiftUI

/// Grid of SF Symbols to choose one from, e.g. the icon of a custom generation. The selected one is filled with
/// `bubblegum`; the rest sit on `fill`. Each icon is a 44 pt button.
public struct DSIconPicker: View {
    private static let size: CGFloat = 44
    @Binding private var selection: String
    private let symbols: [String]
    private let accessibilityLabel: String

    /// - Parameters:
    ///   - symbols: SF Symbol names, in the order they are shown.
    ///   - accessibilityLabel: What VoiceOver says for the group, already localised.
    public init(selection: Binding<String>, symbols: [String], accessibilityLabel: String) {
        self._selection = selection
        self.symbols = symbols
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: Self.size), spacing: DSSpacing.space2)],
            spacing: DSSpacing.space2
        ) {
            ForEach(symbols, id: \.self) { symbol in
                icon(symbol)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func icon(_ symbol: String) -> some View {
        let isSelected = symbol == selection
        return Button {
            withAnimation(.snappy) { selection = symbol }
        } label: {
            Image(systemName: symbol)
                .font(DSFont.body.weight(.semibold))
                .foregroundStyle(isSelected ? DSColor.background : DSColor.textPrimary)
                .frame(width: Self.size, height: Self.size)
                .background(
                    isSelected ? DSPalette.bubblegum : DSColor.fillSecondary,
                    in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous)
                )
        }
        .buttonStyle(DSPressStyle())
        .accessibilityLabel(Text(symbol.replacingOccurrences(of: ".", with: " ")))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = "music.note"
    DSIconPicker(
        selection: $selection,
        symbols: ["music.note", "guitars.fill", "pianokeys", "headphones", "radio.fill", "mic.fill"],
        accessibilityLabel: "Icono"
    )
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
