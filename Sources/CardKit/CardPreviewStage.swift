// The standalone judging stage: the last-saved recipe on the light
// platter, nothing else on screen. The Card Lab embeds the same stage;
// this exists for clean captures and quick side-by-side judging.
//
// The platter is pinned light on purpose, so the stage can never flatter a
// dark design. The real surface blurs and dissolves variably and renders
// glass the simulator cannot; the device is always the final judge.

import SwiftUI

struct CardPreviewStage: View {
    @State private var snoozed = false

    var body: some View {
        ZStack {
            PlatterBackdrop()
            VStack(spacing: 24) {
                let recipe = RecipeStore.load()
                SiriCard(
                    recipe: recipe,
                    line: BriefStore.cardExcerpt(
                        snoozed ? DemoBrief.snoozedLine : recipe.line),
                    snoozed: snoozed
                )
                .frame(width: 340)

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
}

#Preview("Card on the platter") {
    CardPreviewStage()
}
