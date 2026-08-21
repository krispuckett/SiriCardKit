// The intent trio every interactive Siri card needs, with the laws that
// make it behave, each one learned on a real device:
//
// 1. The MAIN intent runs on the phrase, returns a spoken dialog plus the
//    snippet intent. Split the dialog: `full` is what Siri SPEAKS, and
//    `supporting` is the one quiet line the sheet SHOWS, because the card
//    below it already carries the words. Without the split, the sheet
//    prints your whole paragraph above a card that repeats it.
//
// 2. The SNIPPET intent renders the card and MUST be a pure read. The
//    system re-runs it on every redraw: after any control tap, on state
//    restoration, on reload. A mutation here runs twice and lies once.
//
// 3. CONTROL intents do the work. A control that mutates returns plain
//    .result() and the system re-runs the snippet intent to redraw the
//    card in place. Never re-present the snippet from a control, and never
//    point a Button(intent:) at the snippet intent itself.
//
// Execution modes, the short version: an intent that only reads or writes
// data runs .background (no app launch, spoken result, card redraw). An
// intent whose point is the app runs .foreground(.immediate). If your app
// keeps live navigation state, route warm launches through it and use a
// UserDefaults courier ONLY for cold launches, or the flag will hijack the
// next launch.
//
// Phrases: every App Shortcut phrase MUST contain \(.applicationName) or
// Siri will not route it.

import AppIntents
import SwiftUI

// MARK: - The main intent

struct DailyBriefIntent: AppIntent {
    static let title: LocalizedStringResource = "Daily Brief"
    static let description = IntentDescription(
        "Today's focus, steps, and sleep at a glance.",
        categoryName: "Brief"
    )
    static var supportedModes: IntentModes { .background }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        .result(
            dialog: IntentDialog(
                full: "\(BriefStore.spokenLine())",
                supporting: "Today's brief."
            ),
            snippetIntent: BriefSnippetIntent()
        )
    }
}

// MARK: - The snippet intent

struct BriefSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Brief Card"
    /// A card is a surface, not an action: keep it out of Shortcuts.
    static var isDiscoverable: Bool { false }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        // READ ONLY. Current state in, view out. The recipe is whatever the
        // Card Lab last saved, which is the loop's whole point: design in
        // the lab, ask Siri, see YOUR card.
        let snoozed = BriefStore.isSnoozed
        let recipe = RecipeStore.load()
        return .result(view: SiriCard(
            recipe: recipe,
            line: BriefStore.cardExcerpt(snoozed ? DemoBrief.snoozedLine : recipe.line),
            snoozed: snoozed
        ))
    }
}

// MARK: - Control intents

/// The foreground control: its point is the app, so it opens it.
struct StartFocusIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Focus"
    static var supportedModes: IntentModes { .foreground(.immediate) }
    static var isDiscoverable: Bool { false }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Route into your app here. Warm launch: your live navigation
        // object. Cold launch: a UserDefaults courier your root view drains
        // once, after first frame.
        .result()
    }
}

/// The background control: a real mutation, no app launch. After this
/// returns, the system re-runs BriefSnippetIntent and the card redraws in
/// place with the new state, which is the whole trick of an interactive
/// snippet.
struct SnoozeIntent: AppIntent {
    static let title: LocalizedStringResource = "Snooze the Brief"
    static var supportedModes: IntentModes { .background }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Snoozed")
    var snoozed: Bool

    init() {}

    init(snoozed: Bool) {
        self.snoozed = snoozed
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        BriefStore.isSnoozed = snoozed
        return .result(dialog: snoozed ? "Snoozed for an hour." : "Back on.")
    }
}

// MARK: - Phrases

struct KitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DailyBriefIntent(),
            phrases: [
                "How's my day in \(.applicationName)",
                "Daily brief in \(.applicationName)",
                "\(.applicationName) brief",
            ],
            shortTitle: "Brief",
            systemImageName: "sun.horizon"
        )
    }
}

// MARK: - Demo store

/// The demo's whole persistence layer. In your app this is your store; the
/// contract that matters is only that the snippet intent READS it and the
/// control intents WRITE it.
enum BriefStore {
    private static let key = "brief.snoozed"

    static var isSnoozed: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func spokenLine() -> String {
        isSnoozed ? DemoBrief.snoozedLine : RecipeStore.load().line
    }

    /// Whole sentences within a small budget, never a cut mid-thought. The
    /// sheet gives a card one screen; speak everything, show an excerpt.
    static func cardExcerpt(_ line: String?) -> String? {
        guard let line, !line.isEmpty else { return nil }
        let budget = 140
        if line.count <= budget { return line }
        var excerpt = ""
        for sentence in line.components(separatedBy: ". ") {
            let next = excerpt.isEmpty ? sentence : excerpt + ". " + sentence
            if !excerpt.isEmpty, next.count > budget { break }
            excerpt = next
        }
        guard !excerpt.isEmpty else { return line }
        if let last = excerpt.last, !".!?".contains(last) { excerpt += "." }
        return excerpt
    }
}
