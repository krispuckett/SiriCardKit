// The demo card: a morning brief with two live actions. This is the file
// your agent rewrites into YOUR card: keep the bones (eyebrow, headline,
// metric rows, one sentence, wells) and change what they say.
//
// Composition laws that make a snippet read at a glance:
// - One headline wins the first fraction of a second, at 2x or more the
//   scale of everything else.
// - Metric rows are label, value, unit on shared rails, values right
//   aligned, mono, no meters. The card is read, not measured.
// - One sentence at most, and it must never be cut mid-thought: excerpt
//   whole sentences to a budget upstream (see CardIntents.cardExcerpt).
// - Two wells maximum. With nothing to act on, show one.
// - The accent appears exactly once (the eyebrow here).
//
// This view holds only plain values handed in from the intent. No stores,
// no model calls: the system re-renders snippets by re-running the snippet
// intent, so the view must be a pure function of its inputs.

import SwiftUI

struct SiriCard: View {
    let headline: String
    let metrics: [CardMetric]
    let line: String?
    let snoozed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(KitInk.accent)
                Text(headline)
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(KitInk.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(metrics) { metric in
                    CardMetricRow(metric: metric)
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
                    CardWellLabel(title: "Start focus", prominent: true)
                }
                .buttonStyle(.plain)
                .cardWell(prominent: true)

                Button(intent: SnoozeIntent(snoozed: !snoozed)) {
                    CardWellLabel(title: snoozed ? "Resume" : "Snooze it")
                }
                .buttonStyle(.plain)
                .cardWell()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .cardMaterial()
    }
}

// MARK: - Metric rows

struct CardMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let unit: String
}

struct CardMetricRow: View {
    let metric: CardMetric

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(metric.label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(KitInk.tertiary)
            Spacer(minLength: 12)
            Text(metric.value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(KitInk.primary)
            Text(metric.unit)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(KitInk.tertiary)
                .frame(width: 34, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Demo data

enum DemoBrief {
    static let headline = "On track"
    static let metrics = [
        CardMetric(label: "FOCUS", value: "92", unit: "min"),
        CardMetric(label: "STEPS", value: "8,412", unit: ""),
        CardMetric(label: "SLEEP", value: "7:12", unit: "hrs"),
    ]
    static let line = "Two deep blocks done before noon. Guard the afternoon one; it is the one that slips."
    static let snoozedLine = "Snoozed. The afternoon block will call again in an hour."
}
