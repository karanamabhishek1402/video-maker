# Default design

This is the design every project uses **unless** the project supplies its own
`context/<project>/design.md` — a user-provided design file always wins (see
"Design system" in the video-studio SKILL.md). A project design.md should cover
the same headings as this file; anything it omits falls back to the values here.

## Palettes

Two moods; alternate per scene for contrast (dark for mechanism/drama, light
for product-UI tours).

**Dark:**
- Background `#101318`
- Foreground `#EDECE8`
- Accent (red) `#E8384A`

**Light:**
- Background `#F4F3F0`
- Foreground `#0A0E16`
- Accent (red) `#D40816`

Use the accent sparingly — one accent element per frame reads as intent; three
read as noise. Evidence-grade chips and secondary labels sit at ~55–65 %
foreground opacity.

## Type

- Display: a grotesk (reuse font files from an existing build's
  `assets/fonts/` rather than adding new ones).
- Mono: for chips, tags, eyebrows, data labels (`MEASURED`, `READ-ONLY`,
  `ANY SOURCE` style). Eyebrows are letter-spaced uppercase mono.

## Marks

- **Watermark:** product name, small, top-right, persistent — but hidden under
  full-bleed slams, refusal beats, and end lockups (use `set()` calls or
  `data-layout-allow-overlap` as appropriate).
- **End lockup:** `<product> BY <maker>` — product name display-size, the
  "BY <maker>" line small mono beneath. Last beat of the film, on dark.
- Logo files: keep per-project copies in `assets/<project>/logos/`; source
  third-party marks from simpleicons/wikimedia and record where each came from.

## Voice

- Default VO voice: Kokoro `af_sky` at speed `0.80` (see the `vo-pipeline`
  skill for generation rules). A project design.md may name a different
  Kokoro voice/speed.

## Loudness targets

- Final master ≈ **−16.9 LUFS integrated / −3.8 dBTP** (see `mix-master`).
- Music bed −31 LUFS baked, ducked under VO.
