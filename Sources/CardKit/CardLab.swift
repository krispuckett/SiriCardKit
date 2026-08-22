// The Card Lab: design your card IN the thing. The card stays pinned on
// the light platter (the surface Siri really hosts it on) while the
// controls change beneath it, so every edit lands where you can see it.
// Every change saves the recipe, and the demo's snippet intent wears
// whatever you last designed: ask Siri and see your card, before any
// code exists.
//
// Copy recipe puts the design on the pasteboard as text: paste it back
// here to restore a design, or paste it to your agent with the prompt in
// PROMPTS.md to build the card into your own app for real.

import SwiftUI
import UIKit

struct CardLab: View {
    @State private var recipe = RecipeStore.load()
    @State private var snoozedPreview = false
    @State private var panel: LabPanel = .words
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
            Text("ask Siri to see it live")
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
                SiriCard(
                    recipe: recipe,
                    line: BriefStore.cardExcerpt(
                        snoozedPreview ? DemoBrief.snoozedLine : recipe.line),
                    snoozed: snoozedPreview
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
                case .words: wordsPanel
                case .rows: rowsPanel
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
    }

    private var wordsPanel: some View {
        surface {
            field("Eyebrow", text: $recipe.eyebrow, prompt: "TODAY")
            divider
            field("Headline", text: $recipe.headline, prompt: "The one thing that wins the glance")
            divider
            VStack(alignment: .leading, spacing: 6) {
                caption("Sentence")
                TextField("One thought, whole sentences", text: $recipe.line, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundStyle(KitInk.primary)
                    .focused($typing)
            }
            .padding(.vertical, 2)
            divider
            field("Primary button", text: $recipe.primaryTitle, prompt: "The main act")
            divider
            field("Second button", text: $recipe.secondaryTitle,
                  prompt: "Empty shows one button")
        }
    }

    private var rowsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($recipe.rows) { $row in
                surfaceRow {
                    HStack(spacing: 10) {
                        bareField("LABEL", text: $row.label, mono: true)
                            .frame(width: 86)
                        bareField("Value", text: $row.value, mono: true)
                        bareField("unit", text: $row.unit, mono: true)
                            .frame(width: 54)
                        Button {
                            haptic()
                            withAnimation(.easeOut(duration: 0.18)) {
                                recipe.rows.removeAll { $0.id == row.id }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(KitInk.tertiary)
                                .frame(width: 44, height: 44)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove the \(row.label) row")
                    }
                }
            }
            if recipe.rows.count < 4 {
                Button {
                    haptic()
                    withAnimation(.easeOut(duration: 0.18)) {
                        recipe.rows.append(RecipeRow(label: "LABEL", value: "0", unit: ""))
                    }
                } label: {
                    Label("Add a row", systemImage: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(KitInk.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(.white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.06),
                                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            } else {
                Text("Four rows is the ceiling. A card is read, not scrolled.")
                    .font(.system(size: 12))
                    .foregroundStyle(KitInk.tertiary)
                    .padding(.leading, 2)
            }
        }
    }

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
            Text("Spent once, on the eyebrow. One accent is the law.")
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
                    withAnimation(.easeOut(duration: 0.2)) { recipe = pasted }
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

enum LabPanel: String, CaseIterable, Identifiable {
    case words, rows, material, accent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .words: "Words"
        case .rows: "Rows"
        case .material: "Material"
        case .accent: "Accent"
        }
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
