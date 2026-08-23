// The card, rendered from a recipe: an ordered list of blocks on the
// material. The Card Lab edits the blocks, the snippet intent loads the
// recipe, and your agent bakes its values into your app's own card when
// the design settles.
//
// Composition laws that make a snippet read at a glance (enforced as
// rails in CardLaw, honored visually here):
// - One headline wins the first fraction of a second, at 2x or more the
//   scale of everything else.
// - Metric rows are label, value, unit on shared rails, values right
//   aligned, mono, no meters. The card is read, not measured.
// - One sentence at most, and it must never be cut mid-thought: excerpt
//   whole sentences to a budget upstream (see BriefStore.cardExcerpt).
// - Two wells maximum, in one block, always last.
// - The accent appears exactly once: the chip when one exists, the
//   eyebrow otherwise. CardRecipe.chipWearsAccent decides; it is a law,
//   not a setting.
//
// This view holds only plain values handed in from the intent. No stores,
// no model calls: the system re-renders snippets by re-running the snippet
// intent, so the view must be a pure function of its inputs. The canvas
// affordances (selection, onBlockTap) exist only for the lab; the snippet
// passes neither, and the gestures are never attached.

import SwiftUI

struct SiriCard: View {
    let recipe: CardRecipe
    let line: String?
    let snoozed: Bool
    var selection: UUID? = nil
    var onBlockTap: ((UUID) -> Void)? = nil

    private var isEditing: Bool { onBlockTap != nil }

    private var visibleBlocks: [CardBlock] {
        isEditing ? recipe.blocks : recipe.blocks.filter(hasContent)
    }

    var body: some View {
        let units = renderUnits
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                unitView(unit)
                    .padding(.top, index == 0 ? 0 : gap(from: units[index - 1].lead.kind,
                                                        to: unit.lead.kind))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .cardMaterial(recipe.material)
    }

    /// A chip directly after the eyebrow shares its line, trailing: order
    /// is layout, and adjacency is the pairing. Everything else renders
    /// as its own line of the stack.
    private struct RenderUnit: Identifiable {
        let lead: CardBlock
        let trailingChip: CardBlock?
        var id: UUID { lead.id }
    }

    private var renderUnits: [RenderUnit] {
        let blocks = visibleBlocks
        var out: [RenderUnit] = []
        var i = 0
        while i < blocks.count {
            if blocks[i].kind == .eyebrow, i + 1 < blocks.count,
               blocks[i + 1].kind == .chip {
                out.append(RenderUnit(lead: blocks[i], trailingChip: blocks[i + 1]))
                i += 2
            } else {
                out.append(RenderUnit(lead: blocks[i], trailingChip: nil))
                i += 1
            }
        }
        return out
    }

    @ViewBuilder
    private func unitView(_ unit: RenderUnit) -> some View {
        if let chip = unit.trailingChip {
            HStack(alignment: .center, spacing: 12) {
                selectable(unit.lead, fullWidth: false) {
                    blockView(unit.lead)
                }
                Spacer(minLength: 0)
                selectable(chip, fullWidth: false) {
                    blockView(chip)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            selectable(unit.lead) {
                blockView(unit.lead)
            }
        }
    }

    // MARK: Rhythm

    /// The stack's spacing, decided per neighbor pair so the canvas keeps
    /// the template's geometry: a headline sits tight under its eyebrow
    /// (or chip), rows share one rhythm, everything else breathes at 16.
    private func gap(from prev: BlockKind, to next: BlockKind) -> CGFloat {
        if prev == .row && next == .row { return 8 }
        if next == .headline && (prev == .eyebrow || prev == .chip) { return 8 }
        return 16
    }

    // MARK: Blocks

    @ViewBuilder
    private func blockView(_ block: CardBlock) -> some View {
        switch block.kind {
        case .eyebrow:
            Text(displayText(block, placeholder: "EYEBROW").uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(recipe.chipWearsAccent ? KitInk.tertiary : recipe.accent)
                .opacity(block.text.isEmpty ? 0.5 : 1)
        case .headline:
            Text(displayText(block, placeholder: "Headline"))
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(KitInk.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(block.text.isEmpty ? 0.4 : 1)
        case .row:
            CardMetricRow(label: block.label, value: block.value, unit: block.unit,
                          showsUnitRail: hasUnitRail)
        case .columns:
            HStack(alignment: .top, spacing: 12) {
                ForEach(block.cells) { cell in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cell.value)
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(KitInk.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(cell.label.uppercased())
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(KitInk.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        case .sentence:
            Text(sentenceText(block) ?? "One thought, whole sentences")
                .font(.system(size: 15))
                .foregroundStyle(KitInk.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(sentenceText(block) == nil ? 0.4 : 1)
        case .chip:
            Text(displayText(block, placeholder: "STATE").uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(recipe.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(recipe.accent.opacity(0.14), in: Capsule())
                .overlay { Capsule().strokeBorder(recipe.accent.opacity(0.35), lineWidth: 1) }
                .opacity(block.text.isEmpty ? 0.5 : 1)
        case .footnote:
            Text(displayText(block, placeholder: "Quiet metadata"))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(KitInk.tertiary)
                .opacity(block.text.isEmpty ? 0.5 : 1)
        case .wells:
            wellsView(block)
        }
    }

    @ViewBuilder
    private func wellsView(_ block: CardBlock) -> some View {
        HStack(spacing: 12) {
            if isEditing {
                // On the canvas the wells are scenery, so a tap selects
                // the block instead of running an intent.
                CardWellLabel(title: block.primary, prominent: true)
                    .cardWell(depth: recipe.material.wellDepth)
                if !block.secondary.isEmpty {
                    CardWellLabel(title: snoozed ? "Resume" : block.secondary)
                        .cardWell(depth: recipe.material.wellDepth)
                }
            } else {
                Button(intent: StartFocusIntent()) {
                    CardWellLabel(title: block.primary, prominent: true)
                }
                .buttonStyle(.plain)
                .cardWell(depth: recipe.material.wellDepth)

                if !block.secondary.isEmpty {
                    Button(intent: SnoozeIntent(snoozed: !snoozed)) {
                        CardWellLabel(title: snoozed ? "Resume" : block.secondary)
                    }
                    .buttonStyle(.plain)
                    .cardWell(depth: recipe.material.wellDepth)
                }
            }
        }
    }

    // MARK: Content

    private func hasContent(_ block: CardBlock) -> Bool {
        switch block.kind {
        case .eyebrow, .headline, .chip, .footnote: !block.text.isEmpty
        case .sentence: sentenceText(block) != nil
        case .row: !(block.label.isEmpty && block.value.isEmpty)
        case .columns: block.cells.contains { !$0.label.isEmpty || !$0.value.isEmpty }
        case .wells: !(block.primary.isEmpty && block.secondary.isEmpty)
        }
    }

    /// The sentence block wears the excerpted (or snoozed) line the
    /// caller computed; the block's own text is the fallback.
    private func sentenceText(_ block: CardBlock) -> String? {
        let text = line ?? block.text
        return text.isEmpty ? nil : text
    }

    private func displayText(_ block: CardBlock, placeholder: String) -> String {
        block.text.isEmpty ? (isEditing ? placeholder : "") : block.text
    }

    /// The unit rail exists only when some row earned it: a unitless
    /// card's values sit on the true right rail instead of an invisible
    /// column.
    private var hasUnitRail: Bool {
        recipe.blocks.contains { $0.kind == .row && !$0.unit.isEmpty }
    }

    // MARK: Canvas affordances

    @ViewBuilder
    private func selectable(_ block: CardBlock, fullWidth: Bool = true,
                            @ViewBuilder content: () -> some View) -> some View {
        if let onBlockTap {
            content()
                .overlay {
                    if selection == block.id {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.white.opacity(0.85), lineWidth: 1.5)
                            .padding(-6)
                    }
                }
                .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
                .contentShape(.rect)
                .onTapGesture { onBlockTap(block.id) }
        } else {
            content()
        }
    }
}

// MARK: - Metric rows

struct CardMetricRow: View {
    let label: String
    let value: String
    let unit: String
    var showsUnitRail: Bool = true

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(KitInk.tertiary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(KitInk.primary)
            if showsUnitRail {
                Text(unit)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(KitInk.tertiary)
                    .frame(width: 34, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Demo fixtures

enum DemoBrief {
    static let snoozedLine = "Snoozed. The afternoon block will call again in an hour."
}
