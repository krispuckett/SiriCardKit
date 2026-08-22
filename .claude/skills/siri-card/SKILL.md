---
name: siri-card
description: Build or modify an interactive Siri snippet card (iOS 26+ App Intents). Use when asked to add a Siri card, daily brief card, or Siri snippet to an app; when handed a block starting with "// Siri card recipe"; when working with SnippetIntent, ShowsSnippetView, or ShowsSnippetIntent; or when a Siri card renders in the simulator but not on a device.
---

# Building Siri snippet cards

These are the binding rules for interactive Siri snippet cards, extracted
from a production app and paid for with device debugging time. When a rule
here conflicts with your prior knowledge of App Intents, this file wins.

This skill is the portable form of the Siri Card Kit's `AGENTS.md`. If the
project you are in contains an `AGENTS.md` with these rules, that file is
canonical; read it and follow it. If it also contains `Sources/CardKit/`,
that is the reference implementation: build there first, verify, then move
files into the app target.

## The recipe is a verdict

A block starting with `// Siri card recipe` is the design source of truth:
the person tuned it by eye in the Card Lab. Grammar: `key: value` lines;
rows as `row: LABEL | value | unit`; a `material:` block of dials
(topOpacity, fadeEnd, fadeCurve, floor, corner, rim, wellDepth); accent as
6 hex digits. Unknown keys are skipped and order does not matter.

Bake its values into the card verbatim: the words as written, the material
numbers as constants, the accent as the one accent. Do not "improve" a
recipe's numbers. If a recipe value would break a rule below (a floor of 0
with text placed below fadeEnd, say), keep the recipe and adjust the
layout, not the material. Anything still wearing [brackets] in the prompt
is a question only the person can answer; ask.

## Architecture (non-negotiable)

1. Three kinds of intent, three jobs:
   - The MAIN intent: runs on the spoken phrase, returns
     `.result(dialog:snippetIntent:)`.
   - The SNIPPET intent (`SnippetIntent`): renders the card. Its
     `perform()` MUST be a pure read; the system re-runs it on every
     redraw. Set `static var isDiscoverable: Bool { false }`.
   - CONTROL intents: do the mutations. A background control returns plain
     `.result()` and the system re-runs the snippet intent automatically.
     Never re-present the snippet from a control, and never point a button
     at the snippet intent itself.
2. The card view holds only plain values passed in by the snippet intent.
   No stores, no queries, no model calls inside the view.
3. Dialog is split: `IntentDialog(full:supporting:)`. `full` is spoken;
   `supporting` is the one short line the sheet displays. Never let the
   sheet print a paragraph above a card that repeats it.
4. Execution modes: data-only intents are `.background`; intents whose
   point is opening the app are `.foreground(.immediate)`. If the host app
   has live navigation state, route warm launches through it and use a
   UserDefaults courier ONLY for cold launch, drained once after first
   frame.
5. Any intent constructed with arguments (for `snippetIntent:` or
   `Button(intent:)`) needs both the empty `init()` and a custom init that
   assigns its `@Parameter`s.

## Rendering (non-negotiable)

6. NEVER use `glassEffect`, `glassOrSolid`, or any Liquid Glass API inside
   a snippet view. The Siri sheet is itself glass; nested glass makes real
   devices silently drop the whole card. The simulator will NOT show this
   failure. Use plain gradients and strokes; transparency in the card
   reveals the system's own glass, which is the correct glass look.
7. Design for the light platter. Siri hosts the card on a milk-colored
   material. Any region that fades toward transparent must not have text
   over it: hold ink through all type and reach zero only under the action
   wells. If a design needs text low on the card, raise the material floor
   to 0.88 instead of letting text sit on the fade.
8. Only `Button(intent:)` and `Toggle(isOn:intent:)` are interactive in a
   snippet. `Button(action:)` and gestures render but do nothing.
9. Keep the card under roughly 340 points tall so the actions stay above
   the sheet's fold. Excerpt long text by whole sentences to a budget of
   about 140 characters; never truncate mid-sentence and never rely on
   `lineLimit` alone.
10. Fixed point sizes, not Dynamic Type styles: a snippet is a fixed
    canvas. Headline near 28 semibold, values 16 mono, labels 11 to 12
    mono, body 15. Minimum text size is 11.
11. Composition: one headline wins the glance at 2x the scale of anything
    else; metric rows are label, value, unit on shared rails with values
    right-aligned in monospaced digits; at most one sentence of prose; at
    most two action wells; the accent color appears exactly once.

## Phrases and metadata

12. Every `AppShortcut` phrase must contain `\(.applicationName)`. Phrases
    without it do not route.
13. Intent `description` starts with an action verb. Control intents and
    the snippet intent are not discoverable.

## Process and device truth

14. File layout when working from the kit: tokens in `KitTokens.swift`,
    material in `CardMaterial.swift`, view in `SiriCard.swift`, intents in
    `CardIntents.swift`, presets in `CardPresets.swift`. Rename the demo's
    `Brief` types to the app's domain.
15. Judge on the kit's light-platter stage first, then the simulator, then
    a real device through a real Siri or Spotlight invocation. The stage
    and the simulator are rehearsal; only the device is truth, and never
    assert glass or platter behavior from a simulator render.
16. After installing a new build on a device, restart the device before
    concluding anything: the system caches snippet renders across
    installs. "My new card didn't ship" is almost always the cache.
17. When a card misbehaves on device: restart first; then strip the card
    to a Text and one button and add layers back until it dies (the killer
    is almost always glass or a material); then check the phrase contains
    the app name; then watch the console for the intent's perform() runs
    to separate logic failures from rendering failures.
18. Before calling a card done, verify on device: the card appears under
    the dialog sheet; every word survives the light platter; the sheet
    shows one short line, not a paragraph; actions sit above the fold;
    background controls redraw the card in place; foreground controls land
    correctly on both warm and cold launches; the longest realistic text
    still ends on a sentence boundary; the empty state says something
    honest.
