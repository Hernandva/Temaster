import SwiftUI

extension Text {
    /// A text with the string of `key`, looked up in the app's `Localizable.xcstrings` (`Bundle.main`), so the
    /// components of the package show the app's translations. `value` is shown when the catalog does not have the key.
    ///
    /// ```swift
    /// Text(forKey: "vinyl.category", value: "Categoría")
    /// ```
    ///
    /// - Parameters:
    ///   - key: Key of the string in the catalog.
    ///   - value: Text shown when the key is not found, in the development language.
    ///   - table: Catalog to look the key up in; `nil` is `Localizable`.
    ///   - bundle: Bundle of the catalog; the app's by default.
    init(forKey key: String, value: String, table: String? = nil, bundle: Bundle = .main) {
        self.init(verbatim: bundle.localizedString(forKey: key, value: value, table: table))
    }
}
