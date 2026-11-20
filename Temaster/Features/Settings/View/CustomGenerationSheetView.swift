import TemasterUI
import SwiftUI

/// «New generation» sheet of the `custom` play mode: name, icon, first and last year, and «Save» at the end.
/// Shown by `SettingsView` with `.sheet(isPresented:)`; it edits the view model's draft.
struct CustomGenerationSheetView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        DSBottomSheet(
            title: String(localized: "settings.players.custom.sheet.title"),
            primaryAction: .init(
                String(localized: "settings.players.custom.sheet.save"),
                isEnabled: viewModel.canSaveCustomGeneration
            ) {
                viewModel.didTapSaveCustomGeneration()
            }
        ) {
            VStack(alignment: .leading, spacing: DSSpacing.space5) {
                field("settings.players.custom.sheet.name") {
                    DSTextField(value: $viewModel.customGenerationDraft.name)
                        .localized("settings.players.custom.sheet.name.placeholder")
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }
                field("settings.players.custom.sheet.icon") {
                    DSIconPicker(
                        selection: $viewModel.customGenerationDraft.symbolName,
                        symbols: SettingsViewData.CustomGeneration.symbols,
                        accessibilityLabel: String(localized: "settings.players.custom.sheet.icon")
                    )
                }
                field("settings.players.custom.sheet.color") {
                    DSColorPicker(
                        selection: $viewModel.customGenerationDraft.color,
                        options: Self.colors.map { color, name in
                            .init(
                                color,
                                color: DSBingoCategory(color).color,
                                accessibilityLabel: String(localized: name)
                            )
                        },
                        accessibilityLabel: String(localized: "settings.players.custom.sheet.color")
                    )
                }
                years
            }
        }
    }

    /// The colors in the order the picker shows them, with the keys of their names for VoiceOver.
    private static let colors: [(SettingsViewData.BingoColor, String.LocalizationValue)] = [
        (.pink, "settings.players.custom.color.pink"),
        (.yellow, "settings.players.custom.color.yellow"),
        (.cyan, "settings.players.custom.color.cyan"),
        (.green, "settings.players.custom.color.green"),
        (.orange, "settings.players.custom.color.orange")
    ]

    private var years: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space2) {
            HStack(spacing: DSSpacing.space3) {
                field("settings.players.custom.sheet.firstYear") {
                    yearField($viewModel.customGenerationDraft.firstYear, placeholder: "settings.players.custom.past")
                }
                field("settings.players.custom.sheet.lastYear") {
                    yearField($viewModel.customGenerationDraft.lastYear, placeholder: "settings.players.custom.today")
                }
            }
            DSText(style: .footnote, color: DSColor.textSecondary)
                .localized("settings.players.custom.sheet.yearsHint")
            if let error = viewModel.customGenerationYearsError {
                DSText(error, style: .footnote, color: DSColor.destructive)
            }
        }
    }

    /// An empty field shows what it means: «Pasado» or «Actualidad».
    private func yearField(_ value: Binding<String>, placeholder: String) -> some View {
        DSTextField(value: value)
            .localized(placeholder)
            .keyboardType(.numberPad)
    }

    /// A label over its control.
    private func field(_ label: String, @ViewBuilder control: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.space2) {
            DSText(style: .subheadline, color: DSColor.textSecondary)
                .localized(label)
            control()
        }
    }
}
