// The judging stage: your card on an imitation of the surface Siri really
// hosts it on, which is a LIGHT platter over the person's wallpaper. Judge
// here before you judge anywhere else; a card that only ever renders on a
// dark canvas will pass every review and then drown in the milk.
//
// The material here is pinned light on purpose, so the stage can never
// flatter a dark design. The real surface blurs and dissolves variably and
// renders glass the simulator cannot; the device is always the final judge.

import SwiftUI

struct CardPreviewStage: View {
    @State private var snoozed = false

    var body: some View {
        ZStack {
            backdrop
            VStack(spacing: 24) {
                SiriCard(
                    headline: DemoBrief.headline,
                    metrics: DemoBrief.metrics,
                    line: BriefStore.cardExcerpt(snoozed ? DemoBrief.snoozedLine : DemoBrief.line),
                    snoozed: snoozed
                )
                .frame(width: 340)

                // The stage's own toggle, standing in for the control
                // intent's redraw. In a real Siri invocation the buttons on
                // the card run the intents and the system re-renders.
                Button {
                    snoozed.toggle()
                } label: {
                    Text(snoozed ? "Show fresh state" : "Show snoozed state")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .ignoresSafeArea()
    }

    private var backdrop: some View {
        ZStack {
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .color(Color(hex: 0xD8D4CD)))
                let blobs: [(CGFloat, CGFloat, CGFloat, UInt32)] = [
                    (0.22, 0.12, 0.50, 0x2F4E74),
                    (0.86, 0.26, 0.46, 0x8A5628),
                    (0.30, 0.52, 0.44, 0x6C4C7A),
                    (0.78, 0.62, 0.42, 0x2F6B5A),
                    (0.40, 0.88, 0.56, 0x8A3F32),
                ]
                for (x, y, r, hex) in blobs {
                    let radius = r * size.width
                    let centre = CGPoint(x: x * size.width, y: y * size.height)
                    let rect = CGRect(x: centre.x - radius, y: centre.y - radius,
                                      width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .radialGradient(
                        Gradient(colors: [Color(hex: hex), Color(hex: hex).opacity(0)]),
                        center: centre, startRadius: 0, endRadius: radius
                    ))
                }
            }
            .blur(radius: 28)
            Rectangle()
                .fill(.regularMaterial)
                .environment(\.colorScheme, .light)
        }
    }
}

#Preview("Card on the platter") {
    CardPreviewStage()
}
