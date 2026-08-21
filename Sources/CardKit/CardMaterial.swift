// The card's material: ink that melts toward the system's own glass.
//
// Extracted from a production Siri card and shaped by device testing. Two
// laws in here were paid for the hard way:
//
// LAW 1: NO glassEffect ANYWHERE IN A SNIPPET. The Siri sheet is itself
// Liquid Glass, and glass nested inside the system's glass makes the device
// silently drop your whole card: the person gets a dialog sheet with no
// card in it. The simulator's fallback glass renderer hides this, so a sim
// render proving glass "works" proves nothing. The material below is plain
// gradients and strokes, and the system's glass shows through wherever the
// card's ink reaches zero. That IS the liquid glass: theirs, not yours.
//
// LAW 2: THE PLATTER IS MILK. Siri and Spotlight host the card on a light
// material. A dark design that fades to clear lenses that milk, and light
// foreground colors drown on it invisibly. The fade below reaches true
// zero, but SHAPED: a low curve holds ink through every word and plunges
// only under the action wells, so the see-through happens where no type
// lives. If your card must fade under text, raise `floor` instead: at 0.88
// the body stays ink and everything survives, at the cost of the melt.

import SwiftUI

enum CardMaterial {
    /// Ink density at the card's top edge.
    static let topOpacity: Double = 0.95

    /// Where the fade lands, as a FRACTION of the card's height. 0.85 puts
    /// the release under the action row on a card of this composition.
    static let fadeEnd: Double = 0.85

    /// The exponent on the fade. Below 1, the ink lets go off the crest
    /// early and lingers thin; the LOWER the value, the longer ink holds
    /// through the middle before plunging at the end. 0.35 is how a fade
    /// reaches zero without taking your text with it.
    static let fadeCurve: Double = 0.35

    /// The resting alpha at the fade's end. Zero lets the system's glass
    /// shine through; 0.88 is the safe floor if text must sit low.
    static let floor: Double = 0

    /// A continuous corner large enough to read as an object, not a table
    /// cell.
    static let corner: CGFloat = 42

    /// Specular rim strength, 0 to 1.
    static let rim: Double = 1.0

    /// How deeply the action wells are carved, 0 to 1.
    static let wellDepth: Double = 0.73

    static var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
    }

    /// Eleven explicit stops, so the curve is a real curve rather than two
    /// colors with an eased interpolation between them.
    static func inkStops(fadeOver: Double? = nil, floor: Double = floor) -> [Gradient.Stop] {
        let end = fadeOver ?? fadeEnd
        var stops = (0...10).map { i -> Gradient.Stop in
            let t = Double(i) / 10
            let alpha = floor + (topOpacity - floor) * pow(1 - t, fadeCurve)
            return .init(color: KitInk.bgBase.opacity(alpha), location: t * end)
        }
        if end < 1 { stops.append(.init(color: KitInk.bgBase.opacity(floor), location: 1)) }
        return stops
    }

    /// A lens rim, not an outline: bright at the top leading corner, dead
    /// before the bottom trailing one.
    static func rimStyle() -> LinearGradient {
        LinearGradient(stops: [
            .init(color: .white.opacity(0.80 * rim), location: 0),
            .init(color: .white.opacity(0.22 * rim), location: 0.22),
            .init(color: .white.opacity(0.06 * rim), location: 0.55),
            .init(color: .clear, location: 1),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Wear the material: ink gradient as the card's background, rim as its
/// edge. No fill beneath it, so the fade's zero is honest.
struct CardMaterialBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(stops: CardMaterial.inkStops(),
                               startPoint: .top, endPoint: .bottom)
                    .clipShape(CardMaterial.shape)
            }
            .overlay {
                CardMaterial.shape.strokeBorder(CardMaterial.rimStyle(), lineWidth: 1)
            }
    }
}

extension View {
    func cardMaterial() -> some View {
        modifier(CardMaterialBackground())
    }
}
