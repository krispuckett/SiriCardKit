// The card, rendered from a recipe. The Card Lab edits the recipe, the
// snippet intent loads it, and your agent bakes its values into your app's
// own card when the design settles.
//
// Composition laws that make a snippet read at a glance:
// - One headline wins the first fraction of a second, at 2x or more the
//   scale of everything else.
// - Metric rows are label, value, unit on shared rails, values right
//   aligned, mono, no meters. The card is read, not measured.
// - One sentence at most, and it must never be cut mid-thought: excerpt
//   whole sentences to a budget upstream (see BriefStore.cardExcerpt).
// - Two wells maximum. With nothing to act on, show one.
// - The accent appears exactly once (the eyebrow here).
//
// This view holds only plain values handed in from the intent. No stores,
// no model calls: the system re-renders snippets by re-running the snippet
// intent, so the view must be a pure function of its inputs.

import SwiftUI

struct SiriCard: View {
    let recipe: CardRecipe
    let line: String?
    let snoozed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(recipe.accent)
                Text(recipe.headline)
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(KitInk.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(recipe.rows) { row in
                    CardMetricRow(row: row)
                }
            }

            if let line, !line.isEmpty {
                Text(line)
                    .font(.system(size: 15))
                    .foregroundStyle(KitInk.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button(intent: StartFocusIntent()) {
                    CardWellLabel(title: recipe.primaryTitle, prominent: true)
                }
                .buttonStyle(.plain)
                .cardWell(depth: recipe.material.wellDepth)

                if !recipe.secondaryTitle.isEmpty {
                    Button(intent: SnoozeIntent(snoozed: !snoozed)) {
                        CardWellLabel(title: snoozed ? "Resume" : recipe.secondaryTitle)
                    }
                    .buttonStyle(.plain)
                    .cardWell(depth: recipe.material.wellDepth)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .cardMaterial(recipe.material)
    }
}

// MARK: - Metric rows

struct CardMetricRow: View {
    let row: RecipeRow

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(row.label.uppercased())
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(KitInk.tertiary)
            Spacer(minLength: 12)
            Text(row.value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(KitInk.primary)
            Text(row.unit)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(KitInk.tertiary)
                .frame(width: 34, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Demo fixtures

enum DemoBrief {
    static let snoozedLine = "Snoozed. The afternoon block will call again in an hour."
}
