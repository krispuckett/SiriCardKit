# The prompt

Design first, in the app: open the Card Lab, tune the words, rows,
material, and accent until the card is yours, then tap Copy recipe. Then
open this repo in Claude Code (or Codex, or Cursor) and start from this:

```
Read AGENTS.md, then build my card from this recipe.

My app is [what your app is, one sentence].
When someone asks Siri "[the phrase you want]", the card should answer
[the one question this card exists to answer].

The values in my recipe are placeholder content from the lab; wire each
row and the sentence to [where the real data lives in my app].
Buttons: the primary [what it does; open the app or work in place], the
second [same, or "remove it"].

[paste your recipe here]
```

Then:

1. Let the agent build it in `Sources/CardKit/`, renamed to your domain,
   with the recipe's numbers baked in as constants.
2. Judge it on the lab's stage (the light platter), then in the
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
