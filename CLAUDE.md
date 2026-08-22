# Claude Code instructions

Read `AGENTS.md` first; it contains the binding rules for this repo and it
wins over prior knowledge about App Intents and snippets.

Repo-specific notes for Claude Code:

- Never create or edit an `.xcodeproj` by hand. The project is generated:
  `xcodegen generate` from `project.yml`. Change `project.yml` if the
  project needs to change.
- Build check: `xcodegen generate && xcodebuild -project
  SiriCardKitDemo.xcodeproj -scheme SiriCardKitDemo -destination
  'generic/platform=iOS Simulator' build`.
- The user's card lives in their own app in the end. When they ask for
  their card, build it inside `Sources/CardKit/` here first (rename the
  `Brief` types to their domain), verify on the stage and simulator, and
  give them the file list to move into their app target.
- The demo app never ships to the App Store. Do not add features to it
  beyond hosting the card and the stage.
- Simulator screenshots cannot prove glass or platter behavior. When a
  rendering question depends on the device, say so plainly instead of
  asserting from a sim render.

- Read STATUS.md at the start of a session: it carries the working state
  and the open decisions that live outside this repo's code.
