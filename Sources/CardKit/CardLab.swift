// The Card Lab: design your card IN the thing. The card renders live on
// the light platter (the surface Siri really hosts it on), every edit
// saves the recipe, and the demo's snippet intent wears whatever you last
// designed, so "ask Siri, see your card" works before any code exists.
//
// Copy recipe puts the design on the pasteboard as text: paste it back
// here to restore a design, or paste it to your agent with the prompt in
// PROMPTS.md to build the card into your own app for real.

import SwiftUI
import UIKit

struct CardLab: View {
    @State private var recipe = RecipeStore.load()
    @State private var snoozedPreview = false
    @State private var copied = false
    @State private var note: String?

    var body: some View {
        ZStack {
            KitInk.bgBase.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    stage
                    wordsGroup
                    rowsGroup
                    materialGroup
                    accentGroup
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) { actionBar }
        .preferredColorScheme(.dark)
        .onChange(of: recipe) { _, newValue in
            RecipeStore.save(newValue)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Card Lab")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(KitInk.primary)
            Text("Design your card, then ask Siri and see it live.")
                .font(.system(size: 14))
                .foregroundStyle(KitInk.tertiary)
        }
        .padding(.top, 8)
    }

    // MARK: The stage

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
                .frame(maxWidth: 352)
                .padding(.horizontal, 16)
                .padding(.vertical, 28)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))

            // The state the card is previewing, as a quiet control strip in
            // the stage's own frame.
            HStack(spacing: 6) {
                stateChip("Fresh", on: !snoozedPreview) { snoozedPreview = false }
                stateChip("Snoozed", on: snoozedPreview) { snoozedPreview = true }
                Spacer(minLength: 0)
                Text("THE PLATTER IS SIRI'S")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(KitInk.tertiary)
            }
            .padding(12)
            .background(KitInk.bgSurface)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }

    private func stateChip(_ title: String, on: Bool, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(on ? KitInk.bgBase : KitInk.secondary)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(on ? KitInk.primary : Color.white.opacity(0.06), in: Capsule())
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Words

    private var wordsGroup: some View {
        group("Words") {
            field("Eyebrow", text: $recipe.eyebrow)
            divider
            field("Headline", text: $recipe.headline)
            divider
            VStack(alignment: .leading, spacing: 8) {
                caption("Sentence")
                TextField("One thought, whole sentences", text: $recipe.line, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundStyle(KitInk.primary)
            }
            divider
            field("Primary button", text: $recipe.primaryTitle)
            divider
            field("Second button", text: $recipe.secondaryTitle,
                  footnote: "Leave empty to show one button")
        }
    }

    // MARK: Rows

    private var rowsGroup: some View {
        group("Rows") {
            ForEach($recipe.rows) { $row in
                HStack(spacing: 10) {
                    bareField("LABEL", text: $row.label, mono: true)
                        .frame(width: 84)
                    bareField("Value", text: $row.value, mono: true)
                    bareField("unit", text: $row.unit, mono: true)
                        .frame(width: 52)
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            recipe.rows.removeAll { $0.id == row.id }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(KitInk.tertiary)
                            .frame(width: 32, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove the \(row.label) row")
                }
                if row.id != recipe.rows.last?.id { divider }
            }
            if recipe.rows.count < 4 {
                if !recipe.rows.isEmpty { divider }
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        recipe.rows.append(RecipeRow(label: "LABEL", value: "0", unit: ""))
                    }
                } label: {
                    Label("Add a row", systemImage: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(KitInk.secondary)
                        .frame(height: 32)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Material

    private var materialGroup: some View {
        group("Material", footnote: "The fade reaches zero under the buttons by design. Raise the floor if your card carries text low.") {
            dial("Top opacity", value: $recipe.material.topOpacity, in: 0...1)
            divider
            dial("Fade end", value: $recipe.material.fadeEnd, in: 0.15...1)
            divider
            dial("Fade curve", value: $recipe.material.fadeCurve, in: 0.05...4)
            divider
            dial("Floor", value: $recipe.material.floor, in: 0...1)
            divider
            dial("Corner", value: $recipe.material.corner, in: 8...80, decimals: 0)
            divider
            dial("Rim", value: $recipe.material.rim, in: 0...1)
            divider
            dial("Well depth", value: $recipe.material.wellDepth, in: 0...1)
        }
    }

    // MARK: Accent

    private var accentGroup: some View {
        group("Accent", footnote: "Spent once, on the eyebrow. One accent is the law.") {
            HStack(spacing: 10) {
                ForEach([0xC8B6A0, 0x6F8F6A, 0xC9A26D, 0xB0524A, 0x5C7A9E], id: \.self) { hex in
                    Button {
                        recipe.accentHex = UInt32(hex)
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
                            .frame(width: 38, height: 38)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(format: "Accent %06X", hex))
                }
                Spacer(minLength: 0)
                TextField("HEX", text: Binding(
                    get: { String(format: "%06X", recipe.accentHex) },
                    set: { if let hex = UInt32($0, radix: 16) { recipe.accentHex = hex } }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(KitInk.primary)
                .multilineTextAlignment(.trailing)
                .frame(width: 76)
            }
        }
    }

    // MARK: Actions

    private var actionBar: some View {
        HStack(spacing: 10) {
            PasteButton(payloadType: String.self) { strings in
                guard let text = strings.first, let pasted = CardRecipe.read(text) else {
                    Task { @MainActor in note = "not a card recipe" }
                    return
                }
                Task { @MainActor in
                    recipe = pasted
                    note = "recipe loaded"
                }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .tint(KitInk.bgSurface)
            .accessibilityLabel("Paste a recipe")

            Button {
                recipe = CardRecipe()
                RecipeStore.reset()
                note = "reset to the demo"
            } label: {
                Text("Reset")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(KitInk.secondary)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(.white.opacity(0.06), in: Capsule())
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)

            if let note {
                Text(note)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(KitInk.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                UIPasteboard.general.string = recipe.written()
                copied = true
                note = nil
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                Label(copied ? "Copied" : "Copy recipe",
                      systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KitInk.bgBase)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
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

    // MARK: Small pieces

    private func group(_ title: String, footnote: String? = nil,
                       @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(KitInk.tertiary)
                .padding(.leading, 2)
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
            if let footnote {
                Text(footnote)
                    .font(.system(size: 12))
                    .foregroundStyle(KitInk.tertiary)
                    .padding(.leading, 2)
            }
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

    private func field(_ title: String, text: Binding<String>,
                       footnote: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            caption(title)
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(KitInk.primary)
            if let footnote {
                Text(footnote)
                    .font(.system(size: 11))
                    .foregroundStyle(KitInk.tertiary.opacity(0.8))
            }
        }
    }

    private func bareField(_ placeholder: String, text: Binding<String>,
                           mono: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(mono ? .system(size: 14, design: .monospaced) : .system(size: 15))
            .foregroundStyle(KitInk.primary)
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(.black.opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func dial(_ title: String, value: Binding<Double>,
                      in range: ClosedRange<Double>, decimals: Int = 2) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(KitInk.secondary)
                .frame(width: 92, alignment: .leading)
            Slider(value: value, in: range)
                .tint(KitInk.accent)
            Text(String(format: "%.\(decimals)f", value.wrappedValue))
                .font(.system(size: 12, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(KitInk.primary)
                .frame(width: 42, alignment: .trailing)
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
