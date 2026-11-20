import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "bg-night" asset catalog color resource.
    static let bgNight = DeveloperToolsSupport.ColorResource(name: "bg-night", bundle: resourceBundle)

    /// The "bingo-cyan" asset catalog color resource.
    static let bingoCyan = DeveloperToolsSupport.ColorResource(name: "bingo-cyan", bundle: resourceBundle)

    /// The "bingo-green" asset catalog color resource.
    static let bingoGreen = DeveloperToolsSupport.ColorResource(name: "bingo-green", bundle: resourceBundle)

    /// The "bingo-orange" asset catalog color resource.
    static let bingoOrange = DeveloperToolsSupport.ColorResource(name: "bingo-orange", bundle: resourceBundle)

    /// The "bingo-pink" asset catalog color resource.
    static let bingoPink = DeveloperToolsSupport.ColorResource(name: "bingo-pink", bundle: resourceBundle)

    /// The "bingo-yellow" asset catalog color resource.
    static let bingoYellow = DeveloperToolsSupport.ColorResource(name: "bingo-yellow", bundle: resourceBundle)

    /// The "bubblegum" asset catalog color resource.
    static let bubblegum = DeveloperToolsSupport.ColorResource(name: "bubblegum", bundle: resourceBundle)

    /// The "destructive" asset catalog color resource.
    static let destructive = DeveloperToolsSupport.ColorResource(name: "destructive", bundle: resourceBundle)

    /// The "fill" asset catalog color resource.
    static let fill = DeveloperToolsSupport.ColorResource(name: "fill", bundle: resourceBundle)

    /// The "gradient-end" asset catalog color resource.
    static let gradientEnd = DeveloperToolsSupport.ColorResource(name: "gradient-end", bundle: resourceBundle)

    /// The "gradient-mid" asset catalog color resource.
    static let gradientMid = DeveloperToolsSupport.ColorResource(name: "gradient-mid", bundle: resourceBundle)

    /// The "gradient-start" asset catalog color resource.
    static let gradientStart = DeveloperToolsSupport.ColorResource(name: "gradient-start", bundle: resourceBundle)

    /// The "hairline" asset catalog color resource.
    static let hairline = DeveloperToolsSupport.ColorResource(name: "hairline", bundle: resourceBundle)

    /// The "magenta" asset catalog color resource.
    static let magenta = DeveloperToolsSupport.ColorResource(name: "magenta", bundle: resourceBundle)

    /// The "orchid" asset catalog color resource.
    static let orchid = DeveloperToolsSupport.ColorResource(name: "orchid", bundle: resourceBundle)

    /// The "spotify-green" asset catalog color resource.
    static let spotifyGreen = DeveloperToolsSupport.ColorResource(name: "spotify-green", bundle: resourceBundle)

    /// The "surface-1" asset catalog color resource.
    static let surface1 = DeveloperToolsSupport.ColorResource(name: "surface-1", bundle: resourceBundle)

    /// The "surface-2" asset catalog color resource.
    static let surface2 = DeveloperToolsSupport.ColorResource(name: "surface-2", bundle: resourceBundle)

    /// The "text-primary" asset catalog color resource.
    static let textPrimary = DeveloperToolsSupport.ColorResource(name: "text-primary", bundle: resourceBundle)

    /// The "text-secondary" asset catalog color resource.
    static let textSecondary = DeveloperToolsSupport.ColorResource(name: "text-secondary", bundle: resourceBundle)

    /// The "text-tertiary" asset catalog color resource.
    static let textTertiary = DeveloperToolsSupport.ColorResource(name: "text-tertiary", bundle: resourceBundle)

    /// The "tint-fill" asset catalog color resource.
    static let tintFill = DeveloperToolsSupport.ColorResource(name: "tint-fill", bundle: resourceBundle)

    /// The "tint-ink" asset catalog color resource.
    static let tintInk = DeveloperToolsSupport.ColorResource(name: "tint-ink", bundle: resourceBundle)

    /// The "violet" asset catalog color resource.
    static let violet = DeveloperToolsSupport.ColorResource(name: "violet", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

