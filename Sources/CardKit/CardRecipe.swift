// The recipe: one value that carries a whole card, and the handshake at
// the center of this kit. You design in the Card Lab, the lab saves the
// recipe, the demo's snippet intent renders it (so Siri shows YOUR card
// before any code exists), and Copy hands the same recipe to your agent
// as text, which builds it into your app for real.
//
// Since the canvas: a recipe is an ORDERED LIST OF BLOCKS, not a fixed
// template. Render order is list order. The composition laws are rails
// baked into the type (CardLaw): at most one eyebrow, one headline, one
// sentence, one chip, one footnote, one wells block, four rows, and the
// wells always sit last because the material's fade reaches zero only
// beneath them. Every entry point (the canvas, a paste, an agent's hand)
// runs through the same normalization, so an illegal card cannot exist.
//
// The text form is deliberately tolerant to read: people paste it from
// notes apps, and one stray space should never lose a design.

import SwiftUI

// MARK: - Blocks

enum BlockKind: String, Codable, CaseIterable {
    case eyebrow, headline, row, columns, sentence, chip, footnote, wells
}

/// One cell of the columns block: a value that reads big and the label
/// beneath it. Three cells at most; 340 points divides no further.
struct ColumnCell: Codable, Equatable, Identifiable {
    var id = UUID()
    var label = ""
    var value = ""

    private enum CodingKeys: String, CodingKey { case id, label, value }

    init(label: String = "", value: String = "") {
        self.label = label
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        value = try c.decodeIfPresent(String.self, forKey: .value) ?? ""
    }
}

/// One block on the canvas. Storage is flat on purpose: every kind reads
/// the fields it needs and ignores the rest, which keeps Codable, the
/// lab's bindings, and the legacy migration simple.
struct CardBlock: Codable, Equatable, Identifiable {
    var id = UUID()
    var kind: BlockKind
    var text = ""        // eyebrow, headline, sentence, chip, footnote
    var label = ""       // row
    var value = ""       // row
    var unit = ""        // row
    var primary = ""     // wells
    var secondary = ""   // wells
    var cells: [ColumnCell] = []  // columns

    private enum CodingKeys: String, CodingKey {
        case id, kind, text, label, value, unit, primary, secondary, cells
    }

    init(kind: BlockKind, text: String = "", label: String = "",
         value: String = "", unit: String = "", primary: String = "",
         secondary: String = "", cells: [ColumnCell] = []) {
        self.kind = kind
        self.text = text
        self.label = label
        self.value = value
        self.unit = unit
        self.primary = primary
        self.secondary = secondary
        self.cells = cells
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decode(BlockKind.self, forKey: .kind)
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        value = try c.decodeIfPresent(String.self, forKey: .value) ?? ""
        unit = try c.decodeIfPresent(String.self, forKey: .unit) ?? ""
        primary = try c.decodeIfPresent(String.self, forKey: .primary) ?? ""
        secondary = try c.decodeIfPresent(String.self, forKey: .secondary) ?? ""
        cells = try c.decodeIfPresent([ColumnCell].self, forKey: .cells) ?? []
    }
}

extension CardBlock {
    static func eyebrow(_ text: String) -> CardBlock { .init(kind: .eyebrow, text: text) }
    static func headline(_ text: String) -> CardBlock { .init(kind: .headline, text: text) }
    static func row(_ label: String, _ value: String, _ unit: String) -> CardBlock {
        .init(kind: .row, label: label, value: value, unit: unit)
    }
    static func sentence(_ text: String) -> CardBlock { .init(kind: .sentence, text: text) }
    static func chip(_ text: String) -> CardBlock { .init(kind: .chip, text: text) }
    static func footnote(_ text: String) -> CardBlock { .init(kind: .footnote, text: text) }
    static func wells(primary: String, secondary: String = "") -> CardBlock {
        .init(kind: .wells, primary: primary, secondary: secondary)
    }
    static func columns(_ cells: [(String, String)]) -> CardBlock {
        .init(kind: .columns,
              cells: cells.map { ColumnCell(label: $0.0, value: $0.1) })
    }
}

// MARK: - The laws, as rails

/// The composition laws every entry point enforces. The canvas asks
/// `room` before offering a block, `refusal` for the law to print on a
/// disabled choice, and everything that constructs a recipe runs
/// `normalized` so a paste or an agent cannot smuggle in an illegal card.
enum CardLaw {
    static let maxRows = 4
    static let maxColumnCells = 3

    static func limit(for kind: BlockKind) -> Int {
        kind == .row ? maxRows : 1
    }

    static func room(in blocks: [CardBlock], for kind: BlockKind) -> Bool {
        blocks.filter { $0.kind == kind }.count < limit(for: kind)
    }

    /// The law a full card states when a block is refused.
    static func refusal(for kind: BlockKind) -> String {
        switch kind {
        case .row: "Four rows is the ceiling. A card is read, not scrolled."
        case .columns: "One columns block, three cells at most."
        case .headline: "One headline wins the glance."
        case .sentence: "One sentence at most, and it earns its place."
        case .wells: "Two wells maximum, in one block, always last."
        case .eyebrow: "One eyebrow. The accent is spent once."
        case .chip: "One chip. The accent is spent once."
        case .footnote: "One footnote of quiet metadata."
        }
    }

    /// Ink must stay in the dark register: light text lives on it. Any
    /// hue survives; brightness gets scaled down until the words do too.
    static func clampedInk(_ hex: UInt32) -> UInt32 {
        clampedLuminance(hex, to: 0.035)
    }

    /// On the glass finish the accent is foreground on milk: keep the
    /// hue, darken until it holds. The stored accent is untouched; this
    /// only shapes how glass wears it.
    static func clampedGlassAccent(_ hex: UInt32) -> UInt32 {
        clampedLuminance(hex, to: 0.16)
    }

    private static func clampedLuminance(_ hex: UInt32, to cap: Double) -> UInt32 {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        // Gamma-space luminance; close enough for a one-way clamp.
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        guard lum > cap else { return hex }
        let s = cap / lum
        let rr = UInt32((r * s * 255).rounded())
        let gg = UInt32((g * s * 255).rounded())
        let bb = UInt32((b * s * 255).rounded())
        return (rr << 16) | (gg << 8) | bb
    }

    /// First-wins caps, wells pinned last, column cells trimmed to three.
    /// Order is otherwise preserved.
    static func normalized(_ blocks: [CardBlock]) -> [CardBlock] {
        var counts: [BlockKind: Int] = [:]
        var kept: [CardBlock] = []
        var wells: CardBlock?
        for var block in blocks {
            let seen = counts[block.kind, default: 0]
            guard seen < limit(for: block.kind) else { continue }
            counts[block.kind] = seen + 1
            if block.kind == .columns {
                block.cells = Array(block.cells.prefix(maxColumnCells))
            }
            if block.kind == .wells { wells = block } else { kept.append(block) }
        }
        if let wells { kept.append(wells) }
        return kept
    }
}

// MARK: - The material dials

/// The card's finish. `ink` is the dark card: tinted ink melting into the
/// system's glass. `glass` is the full-glass card: the card carries only
/// a white frost, the system's own material does the rest, and the whole
/// foreground flips to dark ink so the words survive the milk. Both obey
/// LAW 1: never `glassEffect`, only transparency revealing theirs.
enum CardFinish: String, Codable {
    case ink, glass

    /// Each finish has its own honest amount of body.
    var defaultTopOpacity: Double {
        self == .glass ? 0.45 : 0.95
    }
}

/// The material dials, with the shipped defaults as the anchor. See
/// CardMaterial.swift for what each one does and the two laws behind them.
struct MaterialRecipe: Codable, Equatable {
    var finish: CardFinish = .ink
    var inkHex: UInt32 = 0x0A0A0B
    var topOpacity: Double = 0.95
    var fadeEnd: Double = 0.85
    var fadeCurve: Double = 0.35
    var floor: Double = 0
    var corner: Double = 42
    var rim: Double = 1.0
    var wellDepth: Double = 0.73

    /// What the gradient is made of: the tinted ink, or the glass
    /// finish's white frost.
    var inkColor: Color {
        finish == .glass ? .white : Color(hex: inkHex)
    }

    private enum CodingKeys: String, CodingKey {
        case finish, inkHex, topOpacity, fadeEnd, fadeCurve, floor, corner,
             rim, wellDepth
    }

    init() {}

    // decodeIfPresent throughout, so designs saved before a dial existed
    // keep loading.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        finish = try c.decodeIfPresent(CardFinish.self, forKey: .finish) ?? .ink
        inkHex = try c.decodeIfPresent(UInt32.self, forKey: .inkHex) ?? 0x0A0A0B
        topOpacity = try c.decodeIfPresent(Double.self, forKey: .topOpacity) ?? 0.95
        fadeEnd = try c.decodeIfPresent(Double.self, forKey: .fadeEnd) ?? 0.85
        fadeCurve = try c.decodeIfPresent(Double.self, forKey: .fadeCurve) ?? 0.35
        floor = try c.decodeIfPresent(Double.self, forKey: .floor) ?? 0
        corner = try c.decodeIfPresent(Double.self, forKey: .corner) ?? 42
        rim = try c.decodeIfPresent(Double.self, forKey: .rim) ?? 1.0
        wellDepth = try c.decodeIfPresent(Double.self, forKey: .wellDepth) ?? 0.73
    }
}

// MARK: - The recipe

struct CardRecipe: Codable, Equatable {
    var blocks: [CardBlock]
    var accentHex: UInt32 = 0xC8B6A0
    var material = MaterialRecipe()

    var accent: Color { Color(hex: accentHex) }

    /// The demo card, block by block.
    init() {
        blocks = [
            .eyebrow("TODAY"),
            .headline("On track"),
            .row("FOCUS", "92", "min"),
            .row("STEPS", "8,412", ""),
            .row("SLEEP", "7:12", "hrs"),
            .sentence("Two deep blocks done before noon. Guard the afternoon one; it is the one that slips."),
            .wells(primary: "Start focus", secondary: "Snooze it"),
        ]
    }

    init(blocks: [CardBlock], accentHex: UInt32 = 0xC8B6A0,
         material: MaterialRecipe = MaterialRecipe()) {
        self.blocks = CardLaw.normalized(blocks)
        self.accentHex = accentHex
        self.material = material
    }

    /// The card's one sentence, if it has one. The main intent speaks it.
    var line: String {
        blocks.first(where: { $0.kind == .sentence })?.text ?? ""
    }

    /// The chip wears the accent when it exists; the eyebrow otherwise.
    /// One accent is the law, so this is decided, not configured.
    var chipWearsAccent: Bool {
        blocks.contains { $0.kind == .chip }
    }

    /// The foreground set for the current finish: light ink on the dark
    /// card, dark ink on glass.
    var inkSet: InkSet {
        material.finish == .glass ? .glass : .dark
    }

    /// The accent as this finish wears it: verbatim on ink, darkened to
    /// hold on glass's light ground.
    var resolvedAccent: Color {
        material.finish == .glass
            ? Color(hex: CardLaw.clampedGlassAccent(accentHex))
            : accent
    }

    private enum CodingKeys: String, CodingKey {
        case blocks, accentHex, material
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accentHex = try c.decodeIfPresent(UInt32.self, forKey: .accentHex) ?? 0xC8B6A0
        material = try c.decodeIfPresent(MaterialRecipe.self, forKey: .material) ?? MaterialRecipe()
        if let stored = try c.decodeIfPresent([CardBlock].self, forKey: .blocks) {
            blocks = CardLaw.normalized(stored)
        } else {
            // A design saved before the canvas: the fixed template, read
            // into blocks in its canonical order.
            blocks = try LegacyRecipe(from: decoder).blocks
        }
    }
}

/// The pre-canvas storage shape, kept only so a saved design survives the
/// upgrade.
private struct LegacyRecipe: Decodable {
    struct LegacyRow: Decodable {
        var label = ""
        var value = ""
        var unit = ""
    }

    var eyebrow: String?
    var headline: String?
    var rows: [LegacyRow]?
    var line: String?
    var primaryTitle: String?
    var secondaryTitle: String?

    var blocks: [CardBlock] {
        var out: [CardBlock] = []
        if let eyebrow, !eyebrow.isEmpty { out.append(.eyebrow(eyebrow)) }
        if let headline, !headline.isEmpty { out.append(.headline(headline)) }
        for row in rows ?? [] where !row.label.isEmpty {
            out.append(.row(row.label, row.value, row.unit))
        }
        if let line, !line.isEmpty { out.append(.sentence(line)) }
        if let primaryTitle, !primaryTitle.isEmpty {
            out.append(.wells(primary: primaryTitle, secondary: secondaryTitle ?? ""))
        }
        return CardLaw.normalized(out)
    }
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
    /// Line order IS block order; the wells write last as primary and
    /// secondary, where they render.
    func written() -> String {
        var out: [String] = ["// Siri card recipe"]
        for block in blocks {
            switch block.kind {
            case .eyebrow: out.append("eyebrow: \(block.text)")
            case .headline: out.append("headline: \(block.text)")
            case .row: out.append("row: \(block.label) | \(block.value) | \(block.unit)")
            case .columns:
                out.append("columns: " + block.cells
                    .map { "\($0.label) | \($0.value)" }
                    .joined(separator: " || "))
            case .sentence: out.append("line: \(block.text)")
            case .chip: out.append("chip: \(block.text)")
            case .footnote: out.append("note: \(block.text)")
            case .wells:
                out.append("primary: \(block.primary)")
                out.append("secondary: \(block.secondary)")
            }
        }
        out.append(String(format: "accent: %06X", accentHex))
        out.append("material:")
        out.append("  finish: \(material.finish.rawValue)")
        out.append(String(format: "  ink: %06X", material.inkHex))
        out.append(String(format: "  topOpacity: %.2f", material.topOpacity))
        out.append(String(format: "  fadeEnd: %.2f", material.fadeEnd))
        out.append(String(format: "  fadeCurve: %.2f", material.fadeCurve))
        out.append(String(format: "  floor: %.2f", material.floor))
        out.append(String(format: "  corner: %.0f", material.corner))
        out.append(String(format: "  rim: %.2f", material.rim))
        out.append(String(format: "  wellDepth: %.2f", material.wellDepth))
        return out.joined(separator: "\n")
    }

    /// The one-tap handoff: the PROMPTS.md scaffold with this recipe
    /// already inside it. The bracketed lines stay bracketed on purpose;
    /// they are the questions only the person can answer, and a good agent
    /// asks about anything still wearing brackets.
    func agentPrompt() -> String {
        """
        Read AGENTS.md, or load the siri-card skill if it's installed, then \
        build my card from this recipe.

        My app is [what your app is, one sentence].
        When someone asks Siri "[the phrase you want]", the card should answer
        [the one question this card exists to answer].

        The values in my recipe are placeholder content from the lab; wire each
        row and the sentence to [where the real data lives in my app].
        Buttons: the primary [what it does; open the app or work in place], the
        second [same, or "remove it"].

        \(written())
        """
    }

    /// Tolerant: unknown keys are skipped, an empty value is an absent
    /// block, and a text with no recognizable line at all returns nil so
    /// "pasted the wrong thing" gets an honest answer. Line order becomes
    /// block order; the laws are applied on the way in (first wins, rows
    /// capped, wells last).
    static func read(_ text: String) -> CardRecipe? {
        var blocks: [CardBlock] = []
        var accentHex: UInt32 = 0xC8B6A0
        var material = MaterialRecipe()
        var wellPrimary = ""
        var wellSecondary = ""
        var sawAnything = false

        for raw in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("//") || line == "material:" { continue }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "eyebrow":
                if !value.isEmpty { blocks.append(.eyebrow(value)) }
                sawAnything = true
            case "headline":
                if !value.isEmpty { blocks.append(.headline(value)) }
                sawAnything = true
            case "row":
                let parts = value.split(separator: "|", omittingEmptySubsequences: false)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                if let label = parts.first, !label.isEmpty {
                    blocks.append(.row(
                        label,
                        parts.count > 1 ? parts[1] : "",
                        parts.count > 2 ? parts[2] : ""
                    ))
                    sawAnything = true
                }
            case "columns":
                let cells = value.components(separatedBy: "||")
                    .map { cell -> (String, String) in
                        let parts = cell.split(separator: "|", omittingEmptySubsequences: false)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        return (parts.first ?? "", parts.count > 1 ? parts[1] : "")
                    }
                    .filter { !$0.0.isEmpty || !$0.1.isEmpty }
                if !cells.isEmpty { blocks.append(.columns(cells)) }
                sawAnything = true
            case "line":
                if !value.isEmpty { blocks.append(.sentence(value)) }
                sawAnything = true
            case "chip":
                if !value.isEmpty { blocks.append(.chip(value)) }
                sawAnything = true
            case "note":
                if !value.isEmpty { blocks.append(.footnote(value)) }
                sawAnything = true
            case "primary": wellPrimary = value; sawAnything = true
            case "secondary": wellSecondary = value; sawAnything = true
            case "accent":
                if let hex = UInt32(value, radix: 16) { accentHex = hex; sawAnything = true }
            case "finish":
                if let finish = CardFinish(rawValue: value.lowercased()) {
                    material.finish = finish
                }
            case "ink":
                if let hex = UInt32(value, radix: 16) {
                    material.inkHex = CardLaw.clampedInk(hex)
                }
            case "topOpacity": material.topOpacity = clamp(value, 0, 1) ?? material.topOpacity
            case "fadeEnd": material.fadeEnd = clamp(value, 0.15, 1) ?? material.fadeEnd
            case "fadeCurve": material.fadeCurve = clamp(value, 0.05, 4) ?? material.fadeCurve
            case "floor": material.floor = clamp(value, 0, 1) ?? material.floor
            case "corner": material.corner = clamp(value, 8, 80) ?? material.corner
            case "rim": material.rim = clamp(value, 0, 1) ?? material.rim
            case "wellDepth": material.wellDepth = clamp(value, 0, 1) ?? material.wellDepth
            default: continue
            }
        }
        if !wellPrimary.isEmpty || !wellSecondary.isEmpty {
            blocks.append(.wells(primary: wellPrimary, secondary: wellSecondary))
        }
        guard sawAnything else { return nil }
        return CardRecipe(blocks: blocks, accentHex: accentHex, material: material)
    }

    private static func clamp(_ text: String, _ lo: Double, _ hi: Double) -> Double? {
        guard let v = Double(text) else { return nil }
        return min(hi, max(lo, v))
    }
}
