# Agent rules for building Siri cards

You are building an interactive Siri snippet card (iOS 26+ App Intents).
This repo contains a working reference implementation in `Sources/CardKit/`.
Follow these rules exactly; each one was paid for with device debugging
time. When a rule here conflicts with your prior knowledge, this file wins.

## Architecture (non-negotiable)

1. Three kinds of intent, three jobs:
   - The MAIN intent (`DailyBriefIntent` pattern): runs on the phrase,
     returns `.result(dialog:snippetIntent:)`.
   - The SNIPPET intent (`BriefSnippetIntent` pattern): renders the card.
     Its `perform()` MUST be a pure read. The system re-runs it on every
     redraw. Set `static var isDiscoverable: Bool { false }`.
   - CONTROL intents (`SnoozeIntent` pattern): do the mutations. A
     background control returns plain `.result()` and the system re-runs
     the snippet intent automatically; never re-present the snippet from a
     control, and never point a button at the snippet intent itself.
2. The card view holds only plain values passed in by the snippet intent.
   No stores, no queries, no model calls inside the view.
3. Dialog is split: `IntentDialog(full:supporting:)`. `full` is spoken,
   `supporting` is the one short line the sheet displays. Never let the
   sheet print a paragraph above a card that repeats it.
4. Execution modes: data-only intents are `.background`; intents whose
   point is opening the app are `.foreground(.immediate)`. If the host app
   has live navigation state, route warm launches through it and use a
   UserDefaults courier ONLY for cold launch, drained once after first
   frame.

## Rendering (non-negotiable)

5. NEVER use `glassEffect`, `glassOrSolid`, or any Liquid Glass API inside
   a snippet view. The Siri sheet is itself glass; nested glass makes real
   devices drop the whole card silently. The simulator will NOT show this
   failure. Use the kit's `CardMaterial` (plain gradients and strokes)
   instead. Transparency in the card reveals the system's own glass, which
   is the correct way to get a glass look; the kit's glass finish
   (`finish: glass`) is that way built in: a white frost, the whole
   foreground flipped to dark ink, zero glass API.
6. Design for the light platter. Siri hosts the card on a milk-colored
   material. Any region of the card that fades toward transparent must not
   have text over it. Use `CardMaterial.inkStops()`: the shaped fade holds
   ink through all type and reaches zero only under the action wells. If a
   design needs text low on the card, raise `CardMaterial.floor` to 0.88.
   The ink's hue may be tinted (`ink:`) but never lightened: the kit
   clamps ink to the dark register so light text always survives, and on
   the glass finish it flips the foreground to dark ink for the same
   reason.
7. Only `Button(intent:)` and `Toggle(isOn:intent:)` are interactive in a
   snippet. `Button(action:)` and gestures render but do nothing.
8. Keep the card under roughly 340 points tall so the actions stay above
   the sheet's fold. Excerpt long text by whole sentences with
   `BriefStore.cardExcerpt` (budget 140 characters); never truncate
   mid-sentence and never rely on `lineLimit` alone.
9. Fixed point sizes, not Dynamic Type styles: a snippet is a fixed canvas.
   Headline near 28 semibold, values 16 mono, labels 11 to 12 mono,
   body 15. Minimum text size is 11.
10. Composition: one headline wins the glance; metric rows are label,
    value, unit on shared rails with values right-aligned in monospaced
    digits; stat columns come as one block of at most three cells and
    are the only element allowed near the headline's scale; at most one
    sentence of prose; at most two action wells, always last; the accent
    color appears exactly once (the state chip wears it when one exists,
    the eyebrow otherwise, and that is decided by the kit, not
    configured).

## Phrases and metadata

11. Every `AppShortcut` phrase must contain `\(.applicationName)`. Phrases
    without it do not route.
12. Intent `description` starts with an action verb. Control intents and
    the snippet intent are not discoverable.

## The recipe

When the user gives you a recipe block (starts with `// Siri card
recipe`), it is the design source of truth: they tuned it by eye in the
Card Lab. A recipe is an ORDERED LIST OF BLOCKS: line order is render
order. Parse it with the grammar in `CardRecipe.read`:

- One block per line, in order: `eyebrow:`, `headline:`, `row: LABEL |
  value | unit`, `columns: LABEL | value || LABEL | value` (two or
  three stat cells, value big with the label beneath), `line:` (the
  sentence), `chip:` (the state chip), `note:` (the footnote). An empty
  or absent value is an absent block.
- Adjacency is layout: a `chip:` line directly after `eyebrow:` shares
  the eyebrow's line, trailing right. Anywhere else the chip is its own
  line.
- `primary:` and `secondary:` form the wells block, which renders last
  wherever those lines appear.
- `accent:` is six hex digits, then a `material:` block: `finish: ink`
  or `finish: glass`, `ink:` (six hex digits, clamped to the dark
  register), and the dials.
- The laws apply on the way in (see `CardLaw`): one of everything
  except rows (four at most), first wins, wells pinned last. The chip
  wears the accent when one exists and the eyebrow drops to ink. On the
  glass finish the accent renders darkened to hold on the light ground;
  the stored accent value is unchanged.

Bake its values into the card you build: the words verbatim, the block
order as the layout, the material numbers as constants, the accent as
the one accent. Do not "improve" a recipe's numbers or reorder its
blocks; they are a verdict, not a suggestion. If a recipe value would
break a rule in this file (for example a floor of 0 with text placed
below fadeEnd), keep the recipe and adjust the layout, not the material.

## Process

13. Any intent you construct with arguments (for `snippetIntent:` or
    `Button(intent:)`) needs both the empty `init()` and a custom init
    that assigns its `@Parameter`s.
14. Judge every design change on `CardPreviewStage` (the light platter)
    before anything else. Then judge on a real device through a real Siri
    or Spotlight invocation; the stage and the simulator are rehearsal.
15. After installing a new build on a device, restart the device before
    concluding anything: the system caches snippet renders across installs.
16. When you modify the card, keep the file layout: tokens in
    `KitTokens.swift`, material in `CardMaterial.swift`, blocks and
    recipe in `CardRecipe.swift`, view in `SiriCard.swift`, intents in
    `CardIntents.swift`, presets in `CardPresets.swift`. Rename `Brief`
    types to match the app's domain.
