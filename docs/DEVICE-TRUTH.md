# Device truth

The simulator renders a friendly fiction of Siri. This checklist is the
difference between "it rendered once" and "it works". Run it before you
conclude a card is done, and again before you conclude one is broken.

## Before you judge anything

- [ ] Built to a REAL device, not just the simulator.
- [ ] Device restarted after install. The system caches snippet renders
      across installs; the most common "my new card didn't ship" is the
      cache serving the old one.
- [ ] The app has been launched once since install, so the system has
      extracted its intents.

## The invocation matrix

- [ ] Spotlight: search your app's name, tap your card's chip under the
      app row. This is the deterministic entry; use it first.
- [ ] Siri by voice, with the app name in the phrase.
- [ ] With the app freshly force-quit (cold launch path).
- [ ] With the app already running in the background (warm path).

## The card itself

- [ ] The card actually appears under the dialog sheet. A dialog with no
      card region usually means glass somewhere in the view: remove every
      glassEffect and material, then restart and retry.
- [ ] Every word survives on the light platter, including whatever sits in
      the card's fade region. Check outdoors brightness if you can.
- [ ] The sheet shows one short supporting line, not a paragraph the card
      repeats.
- [ ] Actions sit above the sheet's fold without scrolling.
- [ ] Each button does its work: background controls redraw the card in
      place with visibly new state; foreground controls land in the right
      place in the app, on both warm and cold launches.
- [ ] Long text days: feed your longest realistic sentence and confirm the
      excerpt ends on a sentence boundary and nothing pushes the wells
      under the fold.
- [ ] Empty days: whatever "no data yet" looks like, make sure the card
      says something honest instead of a default that lies.

## When it misbehaves

1. Restart the device. Seriously, first.
2. Strip the card to a Text and one button; if that appears, add your
   layers back until it stops. The layer that kills it is almost always
   glass or a material.
3. Check the phrase contains the app name.
4. Watch the console for your intent names while invoking: perform() runs
   tell you whether the failure is logic or rendering.
