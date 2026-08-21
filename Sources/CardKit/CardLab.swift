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
        ZStack(alignment: .top) {
            KitInk.bgBase.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stage
                    controls
                }
                .padding(16)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: recipe) { _, newValue in
            RecipeStore.save(newValue)
        }
    }

    // MARK: The stage

    private var stage: some View {
        ZStack {
            PlatterBackdrop()
            VStack(spacing: 12) {
                SiriCard(
                    recipe: recipe,
                    line: BriefStore.cardExcerpt(
                        snoozedPreview ? DemoBrief.snoozedLine : recipe.line),
                    snoozed: snoozedPreview
                )
                .frame(maxWidth: 360)

                Button {
                    snoozedPreview.toggle()
                } label: {
                    Text(snoozedPreview ? "Show fresh state" : "Show snoozed state")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.5))
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: The controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 20) {
            section("Words") {
                labeledField("Eyebrow", text: $recipe.eyebrow)
                labeledField("Headline", text: $recipe.headline)
                VStack(alignment: .leading, spacing: 6) {
                    caption("Sentence")
                    TextField("One line at most, whole sentences",
                              text: $recipe.line, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(KitInk.bgSurface,
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                labeledField("Primary button", text: $recipe.primaryTitle)
                labeledField("Second button (empty hides it)", text: $recipe.secondaryTitle)
            }

            section("Rows") {
                ForEach($recipe.rows) { $row in
                    HStack(spacing: 8) {
                        field("LABEL", text: $row.label).frame(width: 90)
                        field("Value", text: $row.value)
                        field("unit", text: $row.unit).frame(width: 64)
                        Button {
                            recipe.rows.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(KitInk.tertiary)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if recipe.rows.count < 4 {
                    Button {
                        recipe.rows.append(RecipeRow(label: "LABEL", value: "0", unit: ""))
                    } label: {
                        Label("Add a row", systemImage: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(KitInk.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            section("Material") {
                dial("Top opacity", value: $recipe.material.topOpacity, in: 0...1, step: 0.01)
                dial("Fade end", value: $recipe.material.fadeEnd, in: 0.15...1, step: 0.01)
                dial("Fade curve", value: $recipe.material.fadeCurve, in: 0.05...4, step: 0.05)
                dial("Floor", value: $recipe.material.floor, in: 0...1, step: 0.01)
                dial("Corner", value: $recipe.material.corner, in: 8...80, step: 1, decimals: 0)
                dial("Rim", value: $recipe.material.rim, in: 0...1, step: 0.05)
                dial("Well depth", value: $recipe.material.wellDepth, in: 0...1, step: 0.01)
            }

            section("Accent") {
                HStack(spacing: 8) {
                    ForEach([0xC8B6A0, 0x6F8F6A, 0xC9A26D, 0xB0524A, 0x5C7A9E], id: \.self) { hex in
                        Button {
                            recipe.accentHex = UInt32(hex)
                        } label: {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: UInt32(hex)))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(recipe.accentHex == UInt32(hex)
                                                      ? KitInk.primary : .clear, lineWidth: 2)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    field("hex", text: Binding(
                        get: { String(format: "%06X", recipe.accentHex) },
                        set: { if let hex = UInt32($0, radix: 16) { recipe.accentHex = hex } }
                    ))
                    .frame(width: 90)
                }
            }

            bottomBar
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button {
                UIPasteboard.general.string = recipe.written()
                copied = true
                note = nil
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                chip(copied ? "Copied" : "Copy recipe", on: copied)
            }
            .buttonStyle(.plain)

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
            .buttonBorderShape(.capsule)
            .tint(KitInk.bgSurface)

            Button {
                recipe = CardRecipe()
                RecipeStore.reset()
                note = "reset to the demo"
            } label: {
                chip("Reset", on: false)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if let note {
                Text(note)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(KitInk.tertiary)
            }
        }
    }

    // MARK: Small pieces

    private func section(_ title: String,
                         @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(KitInk.tertiary)
            content()
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(KitInk.tertiary)
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            caption(title)
            field(title, text: text)
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .padding(10)
            .background(KitInk.bgSurface,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func dial(_ title: String, value: Binding<Double>,
                      in range: ClosedRange<Double>, step: Double,
                      decimals: Int = 2) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(KitInk.secondary)
                .frame(width: 96, alignment: .leading)
            Slider(value: value, in: range)
                .tint(KitInk.accent)
            Text(String(format: "%.\(decimals)f", value.wrappedValue))
                .font(.system(size: 12, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(KitInk.primary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func chip(_ title: String, on: Bool) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(on ? KitInk.bgBase : KitInk.secondary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(on ? KitInk.accent : KitInk.bgSurface, in: Capsule())
            .contentShape(.capsule)
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
