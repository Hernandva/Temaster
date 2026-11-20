import SwiftUI

/// A button of a sheet (`DSBottomSheet`, `DSSongsSheet`): its title, already localised, its style and its action.
public struct DSSheetAction {
    let title: String
    let style: DSButton.Style
    let isEnabled: Bool
    let handler: @MainActor () -> Void

    /// - Parameter isEnabled: `false` dims the button and keeps it from being tapped, e.g. until a form is valid.
    public init(
        _ title: String,
        style: DSButton.Style = .primary,
        isEnabled: Bool = true,
        handler: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.handler = handler
    }
}

/// Bottom sheet of the design system: a `title`, an optional `message`, optional `content` (e.g. a form) and one or
/// two stacked actions, on the aura background with `radius-sheet` corners and the drag indicator.
///
/// It sizes itself to its content. Present it from `.sheet(item:)` or `.sheet(isPresented:)`:
///
///     .sheet(item: $viewModel.error) { error in
///         DSBottomSheet(
///             title: error.title,
///             message: error.message,
///             primaryAction: .init(String(localized: "common.accept")) { viewModel.dismissError() }
///         )
///     }
///
/// Texts are passed already localised. `content` goes between the message and the actions, aligned to the leading
/// edge.
public struct DSBottomSheet<Content: View>: View {
    /// A button of the sheet.
    public typealias Action = DSSheetAction

    private let title: String
    private let message: String?
    private let primaryAction: Action
    private let secondaryAction: Action?
    private let content: Content
    @State private var contentHeight: CGFloat = 0

    /// - Parameters:
    ///   - primaryAction: Main button, `.primary` by default.
    ///   - secondaryAction: Optional button under it. Pass `style: .plain` for "Not now" or "Cancel".
    ///   - content: Shown between the message and the actions.
    public init(
        title: String,
        message: String? = nil,
        primaryAction: Action,
        secondaryAction: Action? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: DSSpacing.space4) {
            DSText(title, style: .title)
                .accessibilityAddTraits(.isHeader)
            if let message {
                DSText(message, style: .body, color: DSColor.textSecondary)
            }
            content
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: DSSpacing.space2) {
                button(for: primaryAction)
                if let secondaryAction {
                    button(for: secondaryAction)
                }
            }
            .padding(.top, DSSpacing.space2)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, DSSpacing.space6)
        .padding(.top, DSSpacing.space8)
        .padding(.bottom, DSSpacing.space6)
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            contentHeight = height
        }
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DSRadius.radiusSheet)
        .presentationBackground { DSAuraBackground() }
        .tint(DSPalette.bubblegum)
        .preferredColorScheme(.dark)
    }

    private func button(for action: Action) -> some View {
        DSButton(action.title, style: action.style, action: action.handler)
            .disabled(!action.isEnabled)
    }
}

public extension DSBottomSheet where Content == EmptyView {
    /// A sheet with only a title, a message and its actions.
    init(title: String, message: String, primaryAction: Action, secondaryAction: Action? = nil) {
        self.init(title: title, message: message, primaryAction: primaryAction, secondaryAction: secondaryAction) {
            EmptyView()
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DSBottomSheet(
                title: "Da permiso a Apple Music",
                message: "Temaster no tiene acceso a Apple Music. Abre los ajustes y dale permiso.",
                primaryAction: .init("Ir a Ajustes") {},
                secondaryAction: .init("Ahora no", style: .plain) {}
            )
        }
        .background { DSAuraBackground() }
}
