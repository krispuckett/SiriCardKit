// The archetypes: whole starting points, not templates to fill. Each one
// is a complete recipe that already obeys the laws (one headline, shared
// rails, at most one sentence, two wells, the accent spent once), so the
// card you start from is already a card. Pick one in the lab's Presets
// menu, or paste its text form from docs/PRESETS.md.

import Foundation

enum CardPreset: String, CaseIterable, Identifiable {
    case demo, stats, words, confirmation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .demo: "The demo brief"
        case .stats: "The stats card"
        case .words: "The words-only card"
        case .confirmation: "The confirmation card"
        }
    }

    var recipe: CardRecipe {
        switch self {
        case .demo:
            CardRecipe()
        case .stats:
            CardRecipe(
                eyebrow: "THIS WEEK",
                headline: "Trending up",
                rows: [
                    RecipeRow(label: "DISTANCE", value: "86.4", unit: "km"),
                    RecipeRow(label: "CLIMB", value: "1,240", unit: "m"),
                    RecipeRow(label: "TIME", value: "3:58", unit: "hrs"),
                    RecipeRow(label: "RIDES", value: "4", unit: ""),
                ],
                line: "",
                primaryTitle: "Open the log",
                secondaryTitle: "",
                accentHex: 0x5C7A9E
            )
        case .words:
            CardRecipe(
                eyebrow: "EVENING",
                headline: "Wind down",
                rows: [],
                line: "The review is written and tomorrow starts with the hard block. Protect the morning; everything else can move.",
                primaryTitle: "Start wind down",
                secondaryTitle: "Skip tonight",
                accentHex: 0xC9A26D
            )
        case .confirmation:
            CardRecipe(
                eyebrow: "CONFIRMED",
                headline: "You're booked",
                rows: [
                    RecipeRow(label: "WHEN", value: "Tue 3:00", unit: "pm"),
                    RecipeRow(label: "WITH", value: "Dr. Alvarez", unit: ""),
                ],
                line: "",
                primaryTitle: "Add to calendar",
                secondaryTitle: "Undo",
                accentHex: 0x6F8F6A
            )
        }
    }
}
