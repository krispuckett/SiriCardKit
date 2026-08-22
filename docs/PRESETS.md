# Presets

Four whole starting points, as recipes. The lab's Presets menu applies
the same four; these text forms exist so a preset can travel: paste one
into the lab with the Paste button, keep one in a note, or hand one
straight to an agent with the prompt in `PROMPTS.md`.

Each preset already obeys the laws (one headline, shared rails, at most
one sentence, two wells, the accent spent once), so what you start from
is already a card. Tune it in the lab; do not design in the text.

## The demo brief

The kit's default: three rows, a sentence, two wells.

```
// Siri card recipe
eyebrow: TODAY
headline: On track
row: FOCUS | 92 | min
row: STEPS | 8,412 |
row: SLEEP | 7:12 | hrs
line: Two deep blocks done before noon. Guard the afternoon one; it is the one that slips.
primary: Start focus
secondary: Snooze it
accent: C8B6A0
material:
  topOpacity: 0.95
  fadeEnd: 0.85
  fadeCurve: 0.35
  floor: 0.00
  corner: 42
  rim: 1.00
  wellDepth: 0.73
```

## The stats card

Numbers carry it: four rows, no sentence, one well. Because no row here
needs prose, the sentence is explicitly empty.

```
// Siri card recipe
eyebrow: THIS WEEK
headline: Trending up
row: DISTANCE | 86.4 | km
row: CLIMB | 1,240 | m
row: TIME | 3:58 | hrs
row: RIDES | 4 |
line:
primary: Open the log
secondary:
accent: 5C7A9E
material:
  topOpacity: 0.95
  fadeEnd: 0.85
  fadeCurve: 0.35
  floor: 0.00
  corner: 42
  rim: 1.00
  wellDepth: 0.73
```

## The words-only card

No rows at all: the sentence is the card. Good for coaching moments,
summaries, anything where a number would be a lie of precision.

```
// Siri card recipe
eyebrow: EVENING
headline: Wind down
line: The review is written and tomorrow starts with the hard block. Protect the morning; everything else can move.
primary: Start wind down
secondary: Skip tonight
accent: C9A26D
material:
  topOpacity: 0.95
  fadeEnd: 0.85
  fadeCurve: 0.35
  floor: 0.00
  corner: 42
  rim: 1.00
  wellDepth: 0.73
```

## The confirmation card

An act just happened; the card proves it and offers the undo. Two short
rows, no sentence, both wells earning their place.

```
// Siri card recipe
eyebrow: CONFIRMED
headline: You're booked
row: WHEN | Tue 3:00 | pm
row: WITH | Dr. Alvarez |
line:
primary: Add to calendar
secondary: Undo
accent: 6F8F6A
material:
  topOpacity: 0.95
  fadeEnd: 0.85
  fadeCurve: 0.35
  floor: 0.00
  corner: 42
  rim: 1.00
  wellDepth: 0.73
```
