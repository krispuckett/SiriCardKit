# The prompt

Open this repo in Claude Code (or Codex, or Cursor), and start from this,
filled in with your app's truth:

```
Read AGENTS.md, then build my card.

My app is [what your app is, one sentence].
When someone asks Siri "[the phrase you want]", the card should answer
[the one question this card exists to answer].

Headline: [the one thing that should win the glance, e.g. a status word,
a name, a number].
Rows: [two or three label/value/unit facts, e.g. "STREAK 12 days"].
Sentence: [where the one line of prose comes from, or "none"].
Buttons: [one or two actions. For each: what it does, and whether it
should open the app or work in place].

My app's colors: [hex values, or "keep the kit's ink"].
```

Then:

1. Let the agent build it in `Sources/CardKit/`, renamed to your domain.
2. Judge it on `CardPreviewStage` (the light platter), then in the
   simulator, then on a device through a real Siri ask.
3. Walk `docs/DEVICE-TRUTH.md` before you decide anything is broken or
   finished.
4. Ask the agent to move the files into your app target and wire the
   store reads to your real data.

## Prompts that go wrong

- "Make it glassy" leads agents straight into the glassEffect trap. Say
  "let the card fade to reveal the system's glass" instead; the material
  already does it.
- "Show all my stats" makes a dashboard. A card answers one question.
- "Match my app's dark theme exactly" fights the light platter. Keep the
  ink dark, but let the kit's fade shape decide where dark ends.
