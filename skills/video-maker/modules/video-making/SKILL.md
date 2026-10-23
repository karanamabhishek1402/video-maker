---
name: video-making
description: Use when building a narrated product, launch, demo, explainer, partner or story video from animated cards, generated/painted art, or screen recordings — including Hyperframes/GSAP compositions, TTS voice-over (Kokoro, Sarvam), AI image generation with character consistency (Vertex/Gemini), whisper word-timestamps, ffmpeg assembly, synthesized music beds, and sidechain ducking.
---

# Video Making

## Overview

A narrated video is an **audio-locked** artifact. The voice-over is the clock; every visual beat is timed to a phrase boundary that already exists on disk.

**Core principle: generate narration FIRST, measure it, then key animations to those measured times.** Animating first and fitting voice afterwards forces you to re-render every time a word changes.

Three production tracks that meet at assembly:
- **Cards** — HTML/GSAP compositions rendered to silent mp4 (Hyperframes)
- **Art** — AI-generated painted frames, camera-moved inside compositions (never hand-drawn SVG scenery — see Common Mistakes)
- **Footage** — screen recordings, cropped, Ken Burns'd to silent mp4 (ffmpeg)

Narration is muxed at the **section** level, not baked into either.

## The Pipeline

```
0. Tooling         → npx hyperframes skills → READ hyperframes-core first
1. Script          → narration written as paragraphs; visual beats per phrase
2. Narration       → paragraph reads per section (never stitched one-liners)
3. Beat times      → whisper word timestamps on the real audio (the contract)
4. Art / footage   → generate frames (character sheet first) / crop + Ken Burns
5. Compositions    → one per section, SILENT, beats keyed to step 3
6. Sections        → comp + overlays + narration, loudnormed → secN.mp4
7. Final           → lossless concat → ONE continuous bed, sidechain-ducked
8. Verify          → full decode + a frame at EVERY boundary + LUFS/dBTP + LOOK
```

Steps 2–7 must each be **idempotent and skip-if-exists**. Long sessions die; you want to resume, not restart. Write everything to persistent storage, never `/tmp`.

**REQUIRED READING before executing:** `pipeline.md` (commands and templates for each step) and `troubleshooting.md` (failures that will otherwise cost you hours).

## Why Sections, Not One Timeline

Cards and footage cannot live in one composition — footage is a separate file. Build each section as: a full-length silent card render, with footage **composited on top** for its window:

```bash
ffmpeg -i comp.mp4 -i shot.mp4 -filter_complex \
 "[1:v]setpts=PTS+4.7/TB[f];[0:v][f]overlay=0:0:enable='between(t,4.7,10.7)':eof_action=pass[v]" ...
```

The composition simply leaves that window empty. This means a footage swap never re-renders the cards, and a copy edit never re-cuts the footage.

## Quick Reference

| Need | Do this |
|---|---|
| Human-sounding TTS | Whole-paragraph reads per section — the model's own prosody. Stitching one-line clips with silence files sounds robotic and stakeholders hear "stops". |
| A rapid list sequence | ONE continuous read of the whole list, then retime the visuals to its word timestamps — never one clip per item |
| A name mispronounced | Phonetic respelling in the TTS input only; verify by transcribing the result and checking it reads back as the intended word |
| Beat times | Word-level timestamps from whisper on the actual narration wavs |
| Painted/illustrated frames | Image API with a style block + a character sheet passed as reference image to every frame of that character |
| Consistent character | Generate the character sheet FIRST, approve it, reference it everywhere |
| UI scenes in an art film | Put them on a generated backdrop, not a flat hex background |
| Lint a composition | `npx hyperframes lint .` — takes a **directory**, not a file |
| Render | One composition at a time, `-w 2`. Parallel renders get OOM-killed. |
| Crisp UI zoom | `zoompan` on a **full-res still**, never on the video |
| Camera moves on generated art | Upscale stills ~1.4× (lanczos) first so push-ins never soften |
| Music bed | Synthesize it against the edit (chords keyed to scene offsets); mux ONCE at final, sidechain-ducked under the voice |
| Rebuild after an edit | Delete only that `secN.mp4`, re-run; final concat is `-c copy` |
| Music shorter than video | Crossfade the track into a repeat of itself (`acrossfade=d=4`) |

## Non-Negotiables

- **Review every generated frame before animating.** Image models drop the payoff object (a face-down phone became a notebook), turn crowds into surreal double-portraits, and write garbled text on props. Contact-sheet all frames, reject and regenerate — one bad frame ships otherwise.
- **The voice is the clock — even for cycles.** When narration and animation drift, retime the ANIMATION to the audio's word timestamps, never rush the read to fit slots.
- **Look at the output.** Extract a frame at every scene boundary and Read it. Every visual bug in practice — uncropped browser chrome, personal data on screen, an invisible logo, a mistimed reveal, a broken glyph — was found by looking, and none by reading logs.
- **Never ship someone's personal data.** Screen recordings carry bookmarks, account names, phone numbers, open tabs. Crop before use and verify on frames.
- **Claims must be verifiable.** If narration asserts something about a product (security posture, deployment model, a number), confirm it against the source of truth and say so if the docs disagree. A video outlives the conversation.
- **Never render straight to the deliverable path.** Build in a scratch tree, copy the finished file over.

## Common Mistakes

| Mistake | Consequence | Fix |
|---|---|---|
| Hand-authoring representational SVG scenery (rooms, people, props) | Looks like clip art; a full rebuild was rejected wholesale over this | Generate painted frames; hand-authored SVG only for abstract/typographic beats |
| Animate first, narrate second | Every copy tweak re-renders everything | Narration first, always |
| Stitching one-line TTS clips with silence files | Robotic prosody + audible dead stops between lines | Whole-paragraph reads; regenerate the paragraph to change a line |
| Skipping the music bed to "let silence work" | Stakeholders hear it as broken audio, not restraint | Always run a bed; duck it under the voice |
| Muxing music per section | Musical seams at every cut | One continuous bed at final assembly |
| Baking narration into compositions | Can't fix a word without a full re-render | Mux audio at section level |
| Shipping TTS wavs unmeasured | Sarvam returns near 0 dBTP — clipping | `loudnorm` every element: dialogue −18 LUFS, bed ~−31, master ≤−1.5 dBTP |
| Long screen-recording tours | Viewers disengage; nothing is explained | ≤6s per UI hold; animation carries the explanation |
| Trusting the render succeeded | Ships with invisible logos, wrong frames | Extract boundary frames and look |
| Editing the "final" in place | No way back when a change is rejected | Rebuild from sections every time |

## Real-World Impact

Two productions: a 3:25 partner video (6 sections, 5 footage shots, ~10 review rounds — late changes rebuilt in 1–3 min because sections were independent) and a 2:26 story film whose hand-drawn-SVG first cut was rejected wholesale and whose generated-art rebuild (18 frames, ~$1 of image credit) shipped the same day.
