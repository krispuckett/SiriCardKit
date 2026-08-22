// The kit's small design system. Ink, one accent, mono for data.
//
// These are deliberately fixed values, not dynamic text styles: a Siri
// snippet is a fixed canvas rendered by the system, and a card tuned in
// points stays the card you tuned. Swap the palette for your app's own,
// but keep the structure: near-black ink, three steps of foreground, one
// accent spent in exactly one place.

import SwiftUI

/// The card's canvas. One width everywhere a stage renders the card, so the
/// lab, the standalone stage, and a screenshot all tell the same truth. The
/// fold is the height ceiling from the agent rules: past it, Siri's sheet
/// pushes the action wells below the fold.
enum KitCard {
    static let width: CGFloat = 340
    static let foldHeight: CGFloat = 340
}

enum KitInk {
    /// The card's ink. Near-black, never pure black.
    static let bgBase = Color(hex: 0x0A0A0B)
    static let bgSurface = Color(hex: 0x111114)

    static let primary = Color(hex: 0xECECEE)
    static let secondary = Color(hex: 0xA1A1A6)
    static let tertiary = Color(hex: 0x7C7C82)

    /// The one accent. Spend it once per card: the eyebrow OR the state
    /// chip, never both, and never on body text.
    static let accent = Color(hex: 0xC8B6A0)

    /// The demo's state color. In your app this is whatever single hue your
    /// card's state has earned: a readiness tone, a status, a category.
    static let state = Color(hex: 0x6F8F6A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
