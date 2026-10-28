import CoreText
import SwiftUI

/// Root Sans, Wordroot's own face (Inter renamed, see scripts/gen_font.py). Shared by the iPhone, Mac and watch
/// targets. The fonts are registered from the bundle at launch, so there is no Info.plist font list to keep in step.
enum RootSans {
    static func register() {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// The system's point size for a text style, so Root Sans lines up with San Francisco and scales with Dynamic Type.
    static func size(_ style: Font.TextStyle) -> CGFloat {
        #if os(macOS)
        typealias Native = NSFont
        #else
        typealias Native = UIFont
        #endif
        let native: Native.TextStyle
        switch style {
        case .largeTitle: native = .largeTitle
        case .title: native = .title1
        case .title2: native = .title2
        case .title3: native = .title3
        case .headline: native = .headline
        case .subheadline: native = .subheadline
        case .callout: native = .callout
        case .footnote: native = .footnote
        case .caption: native = .caption1
        case .caption2: native = .caption2
        default: native = .body
        }
        return Native.preferredFont(forTextStyle: native).pointSize
    }
}

extension Font {
    /// Root Sans at the system size for `style`.
    static func root(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .custom("Root Sans", size: RootSans.size(style), relativeTo: style).weight(weight)
    }
}
