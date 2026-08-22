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

- More card archetypes as recipes (a stats card, a words-only card, a
  confirmation card) shipped as paste-in presets.
- A recipes gallery in the lab (saved designs, not just the one).
- Accent-aware platter variants for judging on brighter and darker
  wallpapers.
- The agent test loop: a scripted check that a generated card still
  builds and obeys the rules.
