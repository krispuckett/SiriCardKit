# Status

Working state and open decisions, for whoever picks this repo up next,
human or agent. Update this file when either changes.

## Where it stands

- v1 shipped: the card, the material (shaped fade, no-glass law), the
  carved wells, the intent trio, the device-truth checklist, the agent
  rules, the prompt.
- v2 shipped: the Card Lab. The demo app IS the design tool: the card
  pinned on the light platter, panels beneath (Words, Rows, Material,
  Accent), everything saving a recipe live. The demo's snippet intent
  renders the saved recipe, so "design, then ask Siri and see YOUR card"
  works with zero code written. Copy recipe exports the design as text;
  the agent rules treat a pasted recipe as a verdict to bake in.
- UX pass shipped: pinned stage, panel switcher, keyboard Done bar,
  haptics, toast feedback, per-dial defaults with tap-to-reset.
- Pixel pass shipped (2026-08-22): the stage renders the card at true
  size (KitCard.width, no scaleEffect, one width shared with the
  standalone stage), a live fold meter appears when the card passes
  340pt, the unit rail collapses when no row has a unit, the custom hex
  field commits on submit instead of fighting the keyboard, every lab
  control hits 44pt targets, and the accent panel no longer overflows
  on non-Max phones. Verified by simulator screenshots across all four
  presets; glass and platter behavior on device still needs the owner's
  eyes.
- Ease-of-use pass shipped (2026-08-22): a Presets menu in the top bar
  (demo, stats, words-only, confirmation; CardPresets.swift, paste-in
  text in docs/PRESETS.md) and Copy for agent, which puts the whole
  PROMPTS.md scaffold with the recipe embedded on the pasteboard in one
  tap.
- The skill shipped (2026-08-22): .claude/skills/siri-card/SKILL.md, a
  self-contained portable form of AGENTS.md that buyers copy into their
  own repo. Rule: AGENTS.md and the skill change together, AGENTS.md
  wins in this repo (noted in CLAUDE.md).
- The canvas shipped (2026-08-22): the card is an ordered list of
  blocks (eyebrow, headline, row, sentence, chip, footnote, wells) and
  the stage is the editor: tap a block for ring plus inspector (edit,
  move, remove), add row offers only what the laws allow. The laws are
  rails in CardLaw (one of everything but rows at four, first wins,
  wells pinned last; the chip wears the accent and the eyebrow drops to
  ink). Text form gained order-is-layout plus chip: and note: keys; old
  recipes and old saved designs migrate cleanly (LegacyRecipe). Two new
  blocks: state chip and mono footnote. Verified in the simulator
  (regression on presets, legacy decode, chip card, selection); the
  canvas has not yet been judged on device.
- Layout vocabulary + undo shipped (2026-08-23): a columns block (up to
  three stat cells, value big over label; `columns: LABEL | value ||
  ...` in text), the paired header line (a chip directly after the
  eyebrow shares its line, trailing; adjacency is layout), and undo in
  the top bar (coalesced snapshots, press-and-hold for redo). Free-grid
  placement was considered and rejected on purpose: stack laws are the
  product. Columns values sit at 22pt against the 28pt headline; law 10
  reworded from "2x the scale" to "wins the glance" with columns as the
  only element allowed near headline scale. Judge that hierarchy on the
  stage and device.

## Decided (2026-08-24)

- The name is SiriCardKit. README and the skill carry it; the GitHub
  repo rename (siri-card-kit -> SiriCardKit) is the owner's click and
  redirects cleanly.
- Public and free, MIT. LICENSE is committed. The old warning about MIT
  and resale is moot: free forever was chosen on purpose.

## Open, the owner's

- The device pass on the canvas era (canvas, chip, footnote, columns,
  paired line) through a real Siri ask; the last blocker before the
  share. docs/DEVICE-TRUTH.md is the walk.
- The loop video: a short screen recording of design-in-lab, ask Siri,
  copy recipe, agent builds it. It is the strongest possible marketing
  asset and only the owner can record it.
- Positioning note that must survive any listing: this kit adds a
  feature to the buyer's OWN app. The demo never ships to the App Store
  (guidelines 4.2.6 and 4.3a treat commercialized template apps as spam).

## The road to 10/10, ranked (direction approved 2026-08-23)

Three pillars: the canvas earns the word, testing becomes an
instrument, the handoff finishes the job. In impact order:

1. Stress states on the stage: Longest and Empty next to Fresh and
   Snoozed, honest fixtures, and the fold meter grown into a laws bar
   (fold, ink-over-fade, floor) so shippable is a row of green lights.
2. Inline editing: tap the headline, the cursor lands IN the headline
   on the card. The field must be pixel-identical to the text it
   replaces. The biggest feel unlock and the hardest single item.
3. The first minute: on first launch, teach the loop viscerally
   ("this card is already live; ask Siri").
4. The judging strip: the card across four platter lights side by
   side, one tap to export the strip as a PNG (also the share asset).
5. Long-press drag to reorder blocks on the card, springs, wells
   pinned; replaces the inspector arrows.
6. The laws ledger: replace the settings-y blocks list with an
   instrument readout of what is spent and what remains.
7. Skill file templates: recipe to working card in ANY repo with zero
   kit files present; kills the "move the files" step.
8. The agent test loop: recipe lint plus law assertions an agent can
   run after generating a card.
9. A recipes gallery (saved designs, variants, A/B), which also feeds
   stress testing.
10. ShareLink on recipes (phone to Mac without Universal Clipboard).

Rejected on purpose: free-grid placement, font pickers, second
accents, in-app AI generation. Vocabulary over freedom; the rails are
the product.
