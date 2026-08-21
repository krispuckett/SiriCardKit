// The recipe: one value that carries a whole card, and the handshake at
// the center of this kit. You design in the Card Lab, the lab saves the
// recipe, the demo's snippet intent renders it (so Siri shows YOUR card
// before any code exists), and Copy hands the same recipe to your agent
// as text, which builds it into your app for real.
//
// The text form is deliberately tolerant to read: people paste it from
// notes apps, and one stray space should never lose a design.

import SwiftUI

// MARK: - The recipe

struct CardRecipe: Codable, Equatable {
    var eyebrow = "TODAY"
    var headline = "On track"
    var rows: [RecipeRow] = [
        RecipeRow(label: "FOCUS", value: "92", unit: "min"),
        RecipeRow(label: "STEPS", value: "8,412", unit: ""),
        RecipeRow(label: "SLEEP", value: "7:12", unit: "hrs"),
    ]
    var line = "Two deep blocks done before noon. Guard the afternoon one; it is the one that slips."
    var primaryTitle = "Start focus"
    var secondaryTitle = "Snooze it"
    var accentHex: UInt32 = 0xC8B6A0
    var material = MaterialRecipe()

    var accent: Color { Color(hex: accentHex) }
}

struct RecipeRow: Codable, Equatable, Identifiable {
    var id = UUID()
    var label: String
    var value: String
    var unit: String
}

/// The material dials, with the shipped defaults as the anchor. See
/// CardMaterial.swift for what each one does and the two laws behind them.
struct MaterialRecipe: Codable, Equatable {
    var topOpacity: Double = 0.95
    var fadeEnd: Double = 0.85
    var fadeCurve: Double = 0.35
    var floor: Double = 0
    var corner: Double = 42
    var rim: Double = 1.0
    var wellDepth: Double = 0.73
}

// MARK: - Storage

/// Where the lab's design lives so the snippet intent can wear it. In your
/// app the recipe usually stops existing at runtime: the agent bakes its
/// values into your card as constants.
enum RecipeStore {
    private static let key = "cardkit.recipe"

    static func load() -> CardRecipe {
        guard let data = UserDefaults.standard.data(forKey: key),
              let recipe = try? JSONDecoder().decode(CardRecipe.self, from: data)
        else { return CardRecipe() }
        return recipe
    }

    static func save(_ recipe: CardRecipe) {
        if let data = try? JSONEncoder().encode(recipe) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - The text form

extension CardRecipe {
    /// Deterministic: the same recipe always writes the same bytes, so a
    /// design survives a notes app, a chat with an agent, and a diff.
    func written() -> String {
        var out: [String] = [
            "// Siri card recipe",
            "eyebrow: \(eyebrow)",
            "headline: \(headline)",
        ]
        for row in rows {
            out.append("row: \(row.label) | \(row.value) | \(row.unit)")
        }
        out.append("line: \(line)")
        out.append("primary: \(primaryTitle)")
        out.append("secondary: \(secondaryTitle)")
        out.append(String(format: "accent: %06X", accentHex))
        out.append("material:")
        out.append(String(format: "  topOpacity: %.2f", material.topOpacity))
        out.append(String(format: "  fadeEnd: %.2f", material.fadeEnd))
        out.append(String(format: "  fadeCurve: %.2f", material.fadeCurve))
        out.append(String(format: "  floor: %.2f", material.floor))
        out.append(String(format: "  corner: %.0f", material.corner))
        out.append(String(format: "  rim: %.2f", material.rim))
        out.append(String(format: "  wellDepth: %.2f", material.wellDepth))
        return out.joined(separator: "\n")
    }

    /// Tolerant: unknown keys are skipped, order does not matter, and a
    /// recipe with no recognizable line at all returns nil so "pasted the
    /// wrong thing" gets an honest answer.
    static func read(_ text: String) -> CardRecipe? {
        var recipe = CardRecipe()
        recipe.rows = []
        var sawAnything = false

        for raw in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("//") || line == "material:" { continue }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "eyebrow": recipe.eyebrow = value; sawAnything = true
            case "headline": recipe.headline = value; sawAnything = true
            case "row":
                let parts = value.split(separator: "|", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                if let label = parts.first, !label.isEmpty {
                    recipe.rows.append(RecipeRow(
                        label: label,
                        value: parts.count > 1 ? parts[1] : "",
                        unit: parts.count > 2 ? parts[2] : ""
                    ))
                    sawAnything = true
                }
            case "line": recipe.line = value; sawAnything = true
            case "primary": recipe.primaryTitle = value; sawAnything = true
            case "secondary": recipe.secondaryTitle = value; sawAnything = true
            case "accent":
                if let hex = UInt32(value, radix: 16) { recipe.accentHex = hex; sawAnything = true }
            case "topOpacity": recipe.material.topOpacity = clamp(value, 0, 1) ?? recipe.material.topOpacity
            case "fadeEnd": recipe.material.fadeEnd = clamp(value, 0.15, 1) ?? recipe.material.fadeEnd
            case "fadeCurve": recipe.material.fadeCurve = clamp(value, 0.05, 4) ?? recipe.material.fadeCurve
            case "floor": recipe.material.floor = clamp(value, 0, 1) ?? recipe.material.floor
            case "corner": recipe.material.corner = clamp(value, 8, 80) ?? recipe.material.corner
            case "rim": recipe.material.rim = clamp(value, 0, 1) ?? recipe.material.rim
            case "wellDepth": recipe.material.wellDepth = clamp(value, 0, 1) ?? recipe.material.wellDepth
            default: continue
            }
        }
        return sawAnything ? recipe : nil
    }

    private static func clamp(_ text: String, _ lo: Double, _ hi: Double) -> Double? {
        guard let v = Double(text) else { return nil }
        return min(hi, max(lo, v))
    }
}
