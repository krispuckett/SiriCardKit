// The card's material: ink that melts toward the system's own glass. All
// of it is driven by a MaterialRecipe (see CardRecipe.swift), so the Card
// Lab can dial it live and your agent can bake your numbers in.
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
// foreground colors drown on it invisibly. The default fade reaches true
// zero, but SHAPED: a low curve (0.35) holds ink through every word and
// plunges only under the action wells, so the see-through happens where no
// type lives. If your card must carry text low, raise `floor` toward 0.88
// instead: the body stays ink and everything survives, at the cost of the
// melt.

import SwiftUI

enum CardMaterial {
    static func shape(_ m: MaterialRecipe) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: m.corner, style: .continuous)
    }

    /// Eleven explicit stops, so the curve is a real curve rather than two
    /// colors with an eased interpolation between them. The ink is the
    /// recipe's: a dark tint on the ink finish, a white frost on glass;
    /// the same curve shapes both.
    static func inkStops(_ m: MaterialRecipe, fadeOver: Double? = nil) -> [Gradient.Stop] {
        let end = fadeOver ?? m.fadeEnd
        let ink = m.inkColor
        var stops = (0...10).map { i -> Gradient.Stop in
            let t = Double(i) / 10
            let alpha = m.floor + (m.topOpacity - m.floor) * pow(1 - t, m.fadeCurve)
            return .init(color: ink.opacity(alpha), location: t * end)
        }
        if end < 1 { stops.append(.init(color: ink.opacity(m.floor), location: 1)) }
        return stops
    }

    /// A lens rim, not an outline: bright at the top leading corner, dead
    /// before the bottom trailing one.
    static func rimStyle(_ m: MaterialRecipe) -> LinearGradient {
        LinearGradient(stops: [
            .init(color: .white.opacity(0.80 * m.rim), location: 0),
            .init(color: .white.opacity(0.22 * m.rim), location: 0.22),
            .init(color: .white.opacity(0.06 * m.rim), location: 0.55),
            .init(color: .clear, location: 1),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Wear the material: ink gradient as the card's background, rim as its
/// edge. No fill beneath it, so the fade's zero is honest.
struct CardMaterialBackground: ViewModifier {
    let material: MaterialRecipe

    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(stops: CardMaterial.inkStops(material),
                               startPoint: .top, endPoint: .bottom)
                    .clipShape(CardMaterial.shape(material))
            }
            .overlay {
                CardMaterial.shape(material)
                    .strokeBorder(CardMaterial.rimStyle(material), lineWidth: 1)
            }
    }
}

extension View {
    func cardMaterial(_ material: MaterialRecipe) -> some View {
        modifier(CardMaterialBackground(material: material))
    }
}
