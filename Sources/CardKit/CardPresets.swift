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
                blocks: [
                    .eyebrow("THIS WEEK"),
                    .headline("Trending up"),
                    .row("DISTANCE", "86.4", "km"),
                    .row("CLIMB", "1,240", "m"),
                    .row("TIME", "3:58", "hrs"),
                    .row("RIDES", "4", ""),
                    .wells(primary: "Open the log"),
                ],
                accentHex: 0x5C7A9E
            )
        case .words:
            CardRecipe(
                blocks: [
                    .eyebrow("EVENING"),
                    .headline("Wind down"),
                    .sentence("The review is written and tomorrow starts with the hard block. Protect the morning; everything else can move."),
                    .wells(primary: "Start wind down", secondary: "Skip tonight"),
                ],
                accentHex: 0xC9A26D
            )
        case .confirmation:
            CardRecipe(
                blocks: [
                    .eyebrow("CONFIRMED"),
                    .headline("You're booked"),
                    .row("WHEN", "Tue 3:00", "pm"),
                    .row("WITH", "Dr. Alvarez", ""),
                    .footnote("Booked just now. Undo holds for an hour."),
                    .wells(primary: "Add to calendar", secondary: "Undo"),
                ],
                accentHex: 0x6F8F6A
            )
        }
    }
}
