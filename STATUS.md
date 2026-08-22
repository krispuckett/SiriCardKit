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

## Open decisions (the owner's, not an agent's)

- The product's real name. The repo slug is a placeholder; renaming on
  GitHub redirects cleanly.
- Public and free, or private and paid. No LICENSE file is committed on
  purpose: if it ever sells, do NOT use MIT (it permits resale); use a
  standard non-exclusive kit license, updates through iOS 28 rather than
  lifetime.
- The loop video: a short screen recording of design-in-lab, ask Siri,
  copy recipe, agent builds it. It is the strongest possible marketing
  asset and only the owner can record it.
- Positioning note that must survive any listing: this kit adds a
  feature to the buyer's OWN app. The demo never ships to the App Store
  (guidelines 4.2.6 and 4.3a treat commercialized template apps as spam).

## Near-term ideas, unranked

- A recipes gallery in the lab (saved designs, not just the one).
- Accent-aware platter variants for judging on brighter and darker
  wallpapers.
- The agent test loop: a scripted check that a generated card still
  builds and obeys the rules.
