import Foundation

/// Stored format of a custom generation. Internal to TemasterData: the app only sees
/// `SettingsCustomGenerationProtocol`.
struct CustomGenerationDAO: Codable, Sendable, Equatable, SettingsCustomGenerationProtocol {
    let id: String
    let name: String
    let symbolName: String
    let color: SettingsCustomGenerationColor
    let firstYear: Int?
    let lastYear: Int?

    /// Color of the generations saved before they had one, and of an unknown stored color.
    static let defaultColor = SettingsCustomGenerationColor.cyan

    init(
        id: String,
        name: String,
        symbolName: String,
        color: SettingsCustomGenerationColor = Self.defaultColor,
        firstYear: Int?,
        lastYear: Int?
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.color = color
        self.firstYear = firstYear
        self.lastYear = lastYear
    }

    /// A missing or unknown color, e.g. in a generation saved before colors existed, reads as `defaultColor`.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            symbolName: try container.decode(String.self, forKey: .symbolName),
            color: (try? container.decodeIfPresent(SettingsCustomGenerationColor.self, forKey: .color))
                ?? Self.defaultColor,
            firstYear: try container.decodeIfPresent(Int.self, forKey: .firstYear),
            lastYear: try container.decodeIfPresent(Int.self, forKey: .lastYear)
        )
    }

    init(_ generation: some SettingsCustomGenerationProtocol) {
        self.init(
            id: generation.id,
            name: generation.name,
            symbolName: generation.symbolName,
            color: generation.color,
            firstYear: generation.firstYear,
            lastYear: generation.lastYear
        )
    }
}
