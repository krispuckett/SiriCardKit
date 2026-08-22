// The Card Lab: design your card IN the thing. The card stays pinned on
// the light platter (the surface Siri really hosts it on) while the
// controls change beneath it, so every edit lands where you can see it.
// Every change saves the recipe, and the demo's snippet intent wears
// whatever you last designed: ask Siri and see your card, before any
// code exists.
//
// Since the canvas: the card itself is the editor. Tap a block on the
// card to select it (ring on the card, editor beneath), move it, remove
// it; tap the platter to step back to the block list and the add row.
// The composition laws are rails, not homework: the add row only offers
// what the laws still allow, and the wells never leave the bottom.
//
// Copy recipe puts the design on the pasteboard as text: paste it back
// here to restore a design, or use Copy for agent to hand your agent the
// whole prompt with the recipe inside.

import SwiftUI
import UIKit

struct CardLab: View {
    @State private var recipe = RecipeStore.load()
    @State private var snoozedPreview = false
    @State private var panel: LabPanel = .blocks
    @State private var selection: UUID?
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var cardHeight: CGFloat = 0
    @FocusState private var typing: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
            stage
            panelSwitcher
            panelBody
        }
        .background(KitInk.bgBase.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { actionBar }
        .overlay(alignment: .bottom) { toastView }
        .preferredColorScheme(.dark)
        .onChange(of: recipe) { _, newValue in
            RecipeStore.save(newValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { typing = false }
                    .font(.system(size: 15, weight: .semibold))
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Card Lab")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(KitInk.primary)
            Text("tap the card to edit it")
                .font(.system(size: 12))
                .foregroundStyle(KitInk.tertiary)
            Spacer(minLength: 0)
            Menu {
                ForEach(CardPreset.allCases) { preset in
                    Button(preset.title) { apply(preset) }
                }
            } label: {
                Text("Presets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(KitInk.secondary)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(.white.opacity(0.06), in: Capsule())
                    .hitTarget(pad: 7)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: The stage, pinned

    private var stage: some View {
        VStack(spacing: 0) {
            ZStack {
                PlatterBackdrop()
                    .onTapGesture { deselect() }
                SiriCard(
                    recipe: recipe,
                    line: BriefStore.cardExcerpt(
                        snoozedPreview ? DemoBrief.snoozedLine : recipe.line),
                    snoozed: snoozedPreview,
                    selection: selection,
                    onBlockTap: { select($0) }
                )
                // True size, no scale: a scaled preview softens hairlines
                // and judges a card that is not the one Siri renders.
                .frame(maxWidth: KitCard.width)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    cardHeight = height
                }
                .animation(.easeOut(duration: 0.2), value: recipe)
                .animation(.easeOut(duration: 0.2), value: snoozedPreview)
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))

            HStack(spacing: 6) {
                stateChip("Fresh", on: !snoozedPreview) { snoozedPreview = false }
                stateChip("Snoozed", on: snoozedPreview) { snoozedPreview = true }
                Spacer(minLength: 0)
                if cardHeight > KitCard.foldHeight {
                    Text("\(Int(cardHeight))pt tall. Siri folds actions past \(Int(KitCard.foldHeight)).")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(KitInk.secondary)
                } else {
                    Text("Previewing on Siri's surface")
                        .font(.system(size: 11))
                        .foregroundStyle(KitInk.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(KitInk.bgSurface)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
        .padding(.horizontal, 16)
    }

    private func stateChip(_ title: String, on: Bool, _ act: @escaping () -> Void) -> some View {
        Button {
            haptic()
            withAnimation(.easeOut(duration: 0.18)) { act() }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(on ? KitInk.bgBase : KitInk.secondary)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(on ? KitInk.primary : Color.white.opacity(0.06), in: Capsule())
                .hitTarget(pad: 8)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Panels

    private var panelSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(LabPanel.allCases) { p in
                Button {
                    haptic()
                    typing = false
                    withAnimation(.easeOut(duration: 0.18)) { panel = p }
                } label: {
                    Text(p.title)
                        .font(.system(size: 13, weight: panel == p ? .semibold : .medium))
                        .foregroundStyle(panel == p ? KitInk.primary : KitInk.tertiary)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(panel == p ? Color.white.opacity(0.08) : .clear,
                                    in: Capsule())
                        .hitTarget(pad: 6)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(panel == p ? [.isSelected, .isButton] : .isButton)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder private var panelBody: some View {
        ScrollView {
            Group {
                switch panel {
                case .blocks:
                    if let selection, recipe.blocks.contains(where: { $0.id == selection }) {
                        blockEditor(id: selection)
                    } else {
                        blocksOverview
                    }
                case .material: materialPanel
                case .accent: accentPanel
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
            .transition(.opacity)
        }
        .scrollIndicators(.hidden)
        .animation(.easeOut(duration: 0.18), value: panel)
        .animation(.easeOut(duration: 0.18), value: selection)
    }

    // MARK: The canvas panels

    private var blocksOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(recipe.blocks) { block in
                Button {
                    select(block.id)
                } label: {
                    surfaceRow {
                        HStack(spacing: 10) {
                            Text(block.kind.title)
                                .font(.system(size: 12))
                                .foregroundStyle(KitInk.tertiary)
                                .frame(width: 74, alignment: .leading)
                            Text(preview(of: block))
                                .font(.system(size: 14))
                                .foregroundStyle(KitInk.primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(KitInk.tertiary)
                        }
                        .frame(minHeight: 28)
                    }
                }
                .buttonStyle(.plain)
            }

            caption("Add a block")
                .padding(.top, 6)
                .padding(.leading, 2)
            addRow
        }
    }

    /// The add row IS the rails: a kind at its cap shows dimmed and dead,
    /// because the law already spent it.
    private var addRow: some View {
        FlowingChips(kinds: BlockKind.allCases.filter { $0 != .wells } + [.wells]) { kind in
            let room = CardLaw.room(in: recipe.blocks, for: kind)
            Button {
                add(kind)
            } label: {
                Label(kind.title, systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(room ? KitInk.secondary : KitInk.tertiary.opacity(0.5))
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(.white.opacity(room ? 0.06 : 0.03), in: Capsule())
                    .hitTarget(pad: 6)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(room)
            .accessibilityLabel(room ? "Add a \(kind.title) block"
                                     : CardLaw.refusal(for: kind))
        }
    }

    @ViewBuilder private func blockEditor(id: UUID) -> some View {
        if let index = recipe.blocks.firstIndex(where: { $0.id == id }) {
            let kind = recipe.blocks[index].kind
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    Button {
                        deselect()
                    } label: {
                        Label("Blocks", systemImage: "chevron.backward")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(KitInk.secondary)
                            .hitTarget(pad: 14)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                    if kind != .wells {
                        editorControl("chevron.up", label: "Move \(kind.title) up",
                                      enabled: canMove(id, by: -1)) { move(id, by: -1) }
                        editorControl("chevron.down", label: "Move \(kind.title) down",
                                      enabled: canMove(id, by: 1)) { move(id, by: 1) }
                    }
                    editorControl("minus.circle", label: "Remove the \(kind.title) block",
                                  enabled: true) { remove(id) }
                }
                surface {
                    blockFields(index: index)
                }
                if let law = editorLaw(for: kind) {
                    Text(law)
                        .font(.system(size: 12))
                        .foregroundStyle(KitInk.tertiary)
                        .padding(.leading, 2)
                }
            }
        }
    }

    @ViewBuilder private func blockFields(index: Int) -> some View {
        let block = $recipe.blocks[index]
        switch recipe.blocks[index].kind {
        case .eyebrow:
            field("Eyebrow", text: block.text, prompt: "TODAY")
        case .headline:
            field("Headline", text: block.text,
                  prompt: "The one thing that wins the glance")
        case .sentence:
            VStack(alignment: .leading, spacing: 6) {
                caption("Sentence")
                TextField("One thought, whole sentences", text: block.text, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundStyle(KitInk.primary)
                    .focused($typing)
            }
            .padding(.vertical, 2)
        case .row:
            HStack(spacing: 10) {
                bareField("LABEL", text: block.label, mono: true)
                    .frame(width: 86)
                bareField("Value", text: block.value, mono: true)
                bareField("unit", text: block.unit, mono: true)
                    .frame(width: 54)
            }
        case .chip:
            field("Chip", text: block.text, prompt: "LIVE")
        case .footnote:
            field("Footnote", text: block.text, prompt: "Updated just now")
        case .wells:
            field("Primary button", text: block.primary, prompt: "The main act")
            divider
            field("Second button", text: block.secondary,
                  prompt: "Empty shows one button")
        }
    }

    private func editorControl(_ symbol: String, label: String, enabled: Bool,
                               _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(enabled ? KitInk.secondary : KitInk.tertiary.opacity(0.4))
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(enabled)
        .accessibilityLabel(label)
    }

    private func editorLaw(for kind: BlockKind) -> String? {
        switch kind {
        case .chip: "The chip wears the accent; the eyebrow drops to ink while one exists."
        case .row: "Rows share rails: values right-aligned, mono, no meters."
        case .wells: "The wells stay last. The fade reaches zero only beneath them."
        case .sentence: "Whole sentences, excerpted to a budget. Never a cut thought."
        default: nil
        }
    }

    private func preview(of block: CardBlock) -> String {
        switch block.kind {
        case .eyebrow, .headline, .sentence, .chip, .footnote:
            block.text.isEmpty ? "Empty" : block.text
        case .row:
            "\(block.label)  \(block.value) \(block.unit)"
                .trimmingCharacters(in: .whitespaces)
        case .wells:
            block.secondary.isEmpty ? block.primary
                                    : "\(block.primary)  ·  \(block.secondary)"
        }
    }

    // MARK: Canvas mutations

    private func select(_ id: UUID) {
        haptic()
        typing = false
        withAnimation(.easeOut(duration: 0.18)) {
            selection = id
            panel = .blocks
        }
    }

    private func deselect() {
        guard selection != nil else { return }
        haptic()
        typing = false
        withAnimation(.easeOut(duration: 0.18)) { selection = nil }
    }

    private func add(_ kind: BlockKind) {
        guard CardLaw.room(in: recipe.blocks, for: kind) else { return }
        haptic()
        let block = starter(for: kind)
        withAnimation(.easeOut(duration: 0.2)) {
            if kind != .wells,
               let wellsIndex = recipe.blocks.firstIndex(where: { $0.kind == .wells }) {
                recipe.blocks.insert(block, at: wellsIndex)
            } else {
                recipe.blocks.append(block)
            }
            selection = block.id
        }
    }

    private func starter(for kind: BlockKind) -> CardBlock {
        switch kind {
        case .eyebrow: .eyebrow("TODAY")
        case .headline: .headline("Headline")
        case .row: .row("LABEL", "0", "")
        case .sentence: .sentence("One thought, whole sentences.")
        case .chip: .chip("LIVE")
        case .footnote: .footnote("Updated just now")
        case .wells: .wells(primary: "The main act")
        }
    }

    private func canMove(_ id: UUID, by delta: Int) -> Bool {
        guard let i = recipe.blocks.firstIndex(where: { $0.id == id }) else { return false }
        let j = i + delta
        guard recipe.blocks.indices.contains(j) else { return false }
        return recipe.blocks[i].kind != .wells && recipe.blocks[j].kind != .wells
    }

    private func move(_ id: UUID, by delta: Int) {
        guard canMove(id, by: delta),
              let i = recipe.blocks.firstIndex(where: { $0.id == id }) else { return }
        haptic()
        withAnimation(.easeOut(duration: 0.2)) {
            recipe.blocks.swapAt(i, i + delta)
        }
    }

    private func remove(_ id: UUID) {
        haptic()
        withAnimation(.easeOut(duration: 0.2)) {
            recipe.blocks.removeAll { $0.id == id }
            selection = nil
        }
    }

    // MARK: Material and accent

    private var materialPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            surface {
                dial("Top opacity", value: $recipe.material.topOpacity, in: 0...1,
                     default: 0.95)
                divider
                dial("Fade end", value: $recipe.material.fadeEnd, in: 0.15...1,
                     default: 0.85)
                divider
                dial("Fade curve", value: $recipe.material.fadeCurve, in: 0.05...4,
                     default: 0.35)
                divider
                dial("Floor", value: $recipe.material.floor, in: 0...1, default: 0)
                divider
                dial("Corner", value: $recipe.material.corner, in: 8...80,
                     default: 42, decimals: 0)
                divider
                dial("Rim", value: $recipe.material.rim, in: 0...1, default: 1)
                divider
                dial("Well depth", value: $recipe.material.wellDepth, in: 0...1,
                     default: 0.73)
            }
            Text("The fade reaches zero under the buttons by design. If your card carries text low, raise the floor toward 0.88.")
                .font(.system(size: 12))
                .foregroundStyle(KitInk.tertiary)
                .padding(.leading, 2)
        }
    }

    private var accentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            surface {
                HStack(spacing: 12) {
                    ForEach([0xC8B6A0, 0x6F8F6A, 0xC9A26D, 0xB0524A, 0x5C7A9E], id: \.self) { hex in
                        Button {
                            haptic()
                            withAnimation(.easeOut(duration: 0.18)) {
                                recipe.accentHex = UInt32(hex)
                            }
                        } label: {
                            Circle()
                                .fill(Color(hex: UInt32(hex)))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Circle().strokeBorder(
                                        recipe.accentHex == UInt32(hex)
                                            ? KitInk.primary : .white.opacity(0.10),
                                        lineWidth: recipe.accentHex == UInt32(hex) ? 2 : 1)
                                }
                                .frame(width: 40, height: 40)
                                .padding(2)
                                .contentShape(.circle)
                                .padding(-2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(format: "Accent %06X", hex))
                    }
                    Spacer(minLength: 0)
                }
                divider
                HStack(spacing: 12) {
                    caption("Custom hex")
                    Spacer(minLength: 0)
                    AccentHexField(hex: $recipe.accentHex, typing: $typing)
                }
            }
            Text(recipe.chipWearsAccent
                 ? "Spent once, on the chip. One accent is the law."
                 : "Spent once, on the eyebrow. One accent is the law.")
                .font(.system(size: 12))
                .foregroundStyle(KitInk.tertiary)
                .padding(.leading, 2)
        }
    }

    // MARK: Actions

    private var actionBar: some View {
        HStack(spacing: 10) {
            PasteButton(payloadType: String.self) { strings in
                guard let text = strings.first, let pasted = CardRecipe.read(text) else {
                    Task { @MainActor in say("That wasn't a card recipe") }
                    return
                }
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.2)) {
                        selection = nil
                        recipe = pasted
                    }
                    say("Recipe loaded")
                }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
            .tint(KitInk.bgSurface)
            .accessibilityLabel("Paste a recipe")

            Spacer(minLength: 0)

            Button {
                haptic()
                UIPasteboard.general.string = recipe.written()
                say("Recipe copied")
            } label: {
                Label("Recipe", systemImage: "doc.on.doc")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(KitInk.secondary)
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .background(.white.opacity(0.06), in: Capsule())
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)

            Button {
                haptic()
                UIPasteboard.general.string = recipe.agentPrompt()
                say("Prompt and recipe copied. Paste to your agent.")
            } label: {
                Label("Copy for agent", systemImage: "arrow.up.forward.app")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KitInk.bgBase)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .background(KitInk.accent, in: Capsule())
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 0.5)
        }
    }

    private var toastView: some View {
        Group {
            if let toast {
                Text(toast)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(KitInk.primary)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay { Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1) }
                    .padding(.bottom, 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: toast)
        .allowsHitTesting(false)
    }

    // MARK: Feedback

    private func apply(_ preset: CardPreset) {
        haptic()
        typing = false
        withAnimation(.easeOut(duration: 0.2)) {
            selection = nil
            recipe = preset.recipe
        }
        say("\(preset.title) loaded")
    }

    private func say(_ message: String) {
        toastTask?.cancel()
        toast = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    // MARK: Small pieces

    private func surface(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KitInk.bgSurface,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func surfaceRow(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KitInk.bgSurface,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 1)
            }
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.06)).frame(height: 0.5)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(KitInk.tertiary)
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            caption(title)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(KitInk.primary)
                .focused($typing)
        }
        .padding(.vertical, 2)
    }

    private func bareField(_ placeholder: String, text: Binding<String>,
                           mono: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(mono ? .system(size: 14, design: .monospaced) : .system(size: 15))
            .foregroundStyle(KitInk.primary)
            .focused($typing)
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(.black.opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func dial(_ title: String, value: Binding<Double>,
                      in range: ClosedRange<Double>, default defaultValue: Double,
                      decimals: Int = 2) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(KitInk.secondary)
                if abs(value.wrappedValue - defaultValue) > 0.004 {
                    Button {
                        haptic()
                        withAnimation(.easeOut(duration: 0.2)) {
                            value.wrappedValue = defaultValue
                        }
                    } label: {
                        Text(String(format: "default %.\(decimals)f", defaultValue))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(KitInk.tertiary)
                            .hitTarget(pad: 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset \(title) to its default")
                }
            }
            .frame(width: 96, alignment: .leading)
            Slider(value: value, in: range)
                .tint(KitInk.accent)
            Text(String(format: "%.\(decimals)f", value.wrappedValue))
                .font(.system(size: 12, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(KitInk.primary)
                .frame(width: 42, alignment: .trailing)
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Lab furniture

enum LabPanel: String, CaseIterable, Identifiable {
    case blocks, material, accent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blocks: "Blocks"
        case .material: "Material"
        case .accent: "Accent"
        }
    }
}

extension BlockKind {
    var title: String {
        switch self {
        case .eyebrow: "Eyebrow"
        case .headline: "Headline"
        case .row: "Row"
        case .sentence: "Sentence"
        case .chip: "Chip"
        case .footnote: "Footnote"
        case .wells: "Wells"
        }
    }
}

/// A simple flow for the add chips: rows of capsules that wrap, without
/// pulling in a Layout for something this small.
private struct FlowingChips<Content: View>: View {
    let kinds: [BlockKind]
    @ViewBuilder let chip: (BlockKind) -> Content

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 108), spacing: 8, alignment: .leading)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(kinds, id: \.self) { kind in
                chip(kind)
            }
        }
    }
}

/// The custom accent field. It keeps a draft while you type and commits on
/// submit or blur, because a binding that reformats to %06X on every
/// keystroke rewrites the text under the cursor.
private struct AccentHexField: View {
    @Binding var hex: UInt32
    var typing: FocusState<Bool>.Binding
    @State private var draft = ""
    @FocusState private var editing: Bool

    var body: some View {
        TextField("C8B6A0", text: $draft)
            .textFieldStyle(.plain)
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(KitInk.primary)
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .focused(typing)
            .focused($editing)
            .frame(width: 74)
            .onAppear { draft = String(format: "%06X", hex) }
            .onChange(of: hex) { _, newValue in
                if !editing { draft = String(format: "%06X", newValue) }
            }
            .onChange(of: editing) { _, isEditing in
                if !isEditing { commit() }
            }
            .onSubmit { commit() }
    }

    private func commit() {
        let cleaned = draft.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
        if cleaned.count == 6, let value = UInt32(cleaned, radix: 16) {
            hex = value
        }
        draft = String(format: "%06X", hex)
    }
}

private extension View {
    /// A 44pt hit area without a 44pt layout: pad to the target, take the
    /// hit shape, then hand the layout back.
    func hitTarget(pad: CGFloat) -> some View {
        self
            .padding(.vertical, pad)
            .contentShape(.rect)
            .padding(.vertical, -pad)
    }
}

/// The platter, extracted so the lab's stage and the standalone preview
/// share one truth about what the card sits on.
struct PlatterBackdrop: View {
    var body: some View {
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

#Preview("Card Lab") {
    CardLab()
}
