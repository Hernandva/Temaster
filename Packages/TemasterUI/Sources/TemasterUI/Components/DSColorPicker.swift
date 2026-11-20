import SwiftUI

/// Row of color circles to choose one from, e.g. the color of a custom generation. The selected one shows a
/// `text-primary` ring and a checkmark in `bg-night`, so the colors should be light ones. Each circle is a 44 pt
/// button.
public struct DSColorPicker<Value: Hashable>: View {
    /// A color the user can choose: its value, its look and its name for VoiceOver, already localised.
    public struct Option {
        let value: Value
        let color: Color
        let accessibilityLabel: String

        public init(_ value: Value, color: Color, accessibilityLabel: String) {
            self.value = value
            self.color = color
            self.accessibilityLabel = accessibilityLabel
        }
    }

    private static var size: CGFloat { 44 }
    private static var swatch: CGFloat { 32 }
    @Binding private var selection: Value
    private let options: [Option]
    private let accessibilityLabel: String

    /// - Parameter accessibilityLabel: What VoiceOver says for the group, already localised.
    public init(selection: Binding<Value>, options: [Option], accessibilityLabel: String) {
        self._selection = selection
        self.options = options
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        HStack(spacing: DSSpacing.space2) {
            ForEach(options.indices, id: \.self) { index in
                swatch(options[index])
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func swatch(_ option: Option) -> some View {
        let isSelected = option.value == selection
        return Button {
            withAnimation(.snappy) { selection = option.value }
        } label: {
            Circle()
                .fill(option.color)
                .frame(width: Self.swatch, height: Self.swatch)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(DSFont.footnote.weight(.bold))
                            .foregroundStyle(DSColor.background)
                    }
                }
                .padding(3)
                .overlay {
                    Circle().strokeBorder(isSelected ? DSColor.textPrimary : .clear, lineWidth: 2)
                }
                .frame(width: Self.size, height: Self.size)
                .contentShape(Circle())
        }
        .buttonStyle(DSPressStyle())
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = DSBingoCategory.cyan
    DSColorPicker(
        selection: $selection,
        options: DSBingoCategory.allCases.map { .init($0, color: $0.color, accessibilityLabel: "\($0)") },
        accessibilityLabel: "Color"
    )
    .padding(DSSpacing.space4)
    .background(DSColor.background)
}
