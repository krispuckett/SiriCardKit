# Siri Card Kit

Build a designed, interactive Siri card for your iOS app, with an AI agent
doing the typing.

iOS 26 gave apps interactive Siri snippets: real cards with live buttons
that Siri and Spotlight present when someone asks about your app. Apple's
documentation teaches the API. This kit teaches the part that is not
written down: how to make a card that looks designed, and the specific
failures that make cards silently not appear on real devices while the
simulator swears everything is fine.

Everything in here was extracted from a production app and verified on
device.

## How it works: design in the thing

The demo app IS a design tool. Open it and you are in the **Card Lab**:
your card rendered live on the light platter Siri actually hosts cards
on, with every word, row, material dial, and the accent editable beneath
it. Every edit saves a **recipe**, and the demo's own Siri intent renders
whatever you last designed, so you can put down the lab, ask Siri, and
see YOUR card in the real surface before a line of code exists.

When the design settles, **Copy recipe** puts it on the pasteboard as
plain text. That text is the handshake: paste it back into the lab to
restore a design, or paste it to Claude Code, Codex, or Cursor with the
prompt in `PROMPTS.md`, and the agent builds the card into your own app
with your exact numbers and words.

## What's in the box

- `Sources/CardKit/CardLab.swift` - the design tool: live card, word
  fields, row editor, material dials, accent, Copy and Paste recipe.
- `Sources/CardKit/CardRecipe.swift` - the recipe: one value that carries
  a whole card, with a tolerant text form for round-tripping through
  notes apps and agent chats.
- `Sources/CardKit/` - the card itself: the material (ink that melts into
  the system's own glass), the carved action wells, the metric row
  grammar, and the full intent trio (main intent, snippet intent, control
  intents) with every hard-won rule written next to the code it protects.
- `AGENTS.md` / `CLAUDE.md` - rules files that make agents build your
  card correctly the first time, including how to read a recipe.
- `PROMPTS.md` - the prompt to hand your agent along with your recipe.
- `docs/DEVICE-TRUTH.md` - the checklist that separates "renders in the
  sim" from "works in Siri on a phone".

## Quickstart

1. Clone this repo.
2. `brew install xcodegen` if you don't have it, then `xcodegen generate`
   and open `SiriCardKitDemo.xcodeproj`.
3. Run it. Design your card in the lab: words, rows, dials, accent.
4. On a device, ask Siri: "Daily brief in Card Kit". That is your design
   in the real surface.
5. Tap Copy recipe, then hand the recipe and the prompt in `PROMPTS.md`
   to your agent to build the card into your own app.

## The five failures this kit exists to prevent

1. **Glass kills the card.** `glassEffect` anywhere in a snippet makes
   real devices drop the entire card and show a bare dialog sheet. The
   simulator's fallback renderer hides this completely.
2. **The platter is milk.** Siri hosts cards on a light material. Dark
   designs that fade to clear drown their own text in it. The kit's
   material fades on a shaped curve that reaches zero only where no type
   lives.
3. **The system caches snippet renders across installs.** Ship a new card,
   see the old one. Restart the device to flush it before you conclude
   your build is broken.
4. **Phrases without the app name do not route.** Every App Shortcut
   phrase must contain `\(.applicationName)`.
5. **Dead buttons.** Only `Button(intent:)` and `Toggle(isOn:intent:)`
   are alive inside a snippet. Closures render and do nothing.

There are more rules than these five. They live in `AGENTS.md`, next to
the reasons.

## What this kit is not

It does not ship an app for you. The demo target exists to host the card
while you design; the card belongs inside your own app. Do not submit the
demo to the App Store: Apple's guidelines (4.2.6, 4.3a) treat
commercialized template apps as spam, and they are right to.

## Requirements

- iOS 26 or later (interactive snippets are an iOS 26 API)
- Xcode 26 or later
- A real device for final judgment. This is not optional; see
  `docs/DEVICE-TRUTH.md`.
