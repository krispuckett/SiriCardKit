// The card's action wells: buttons carved into the material instead of
// raised on top of it. Solid fills and strokes only, per the no-glass law
// in CardMaterial.swift; the inner shadow is drawn as a blurred stroke
// masked back to the capsule, because a fill's own inner shadow needs
// something opaque to shade and these sit over a fading ink.
//
// Inside a snippet, a control is ONLY live when it is Button(intent:) or
// Toggle(isOn:intent:). A Button(action:) closure renders and does nothing.

import SwiftUI

struct CardWellSkin: ViewModifier {
    var depth: Double = 0.73

    func body(content: Content) -> some View {
        content
            .background(Capsule().fill(Color.black.opacity(0.18 + 0.42 * depth)))
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.black.opacity(0.30 + 0.55 * depth),
                                     .black.opacity(0.05 + 0.18 * depth)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 3 + 7 * depth
                    )
                    .blur(radius: 2 + 5 * depth)
                    .mask(Capsule())
            }
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.04 + 0.10 * depth), lineWidth: 0.75)
                    .mask(LinearGradient(colors: [.clear, .black],
                                         startPoint: .center, endPoint: .bottom))
            }
    }
}

/// A well's label, in the carved register: type sits IN the material, so
/// its ink rides slightly below full opacity.
struct CardWellLabel: View {
    let title: String
    var prominent: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle((prominent ? KitInk.primary : KitInk.secondary).opacity(0.92))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(.capsule)
    }
}

extension View {
    func cardWell(depth: Double = 0.73) -> some View {
        modifier(CardWellSkin(depth: depth))
    }
}
