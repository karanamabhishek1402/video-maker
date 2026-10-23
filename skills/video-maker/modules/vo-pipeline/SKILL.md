---
name: vo-pipeline
description: Use when writing or generating voiceover for a video-studio project, fixing pronunciation, extracting word timestamps, or retiming visuals to narration — Kokoro breath-group TTS, faster-whisper word timings, and the VO-first retime loop. Covers gen_vo.py SPEC format, rephrase-not-respell pronunciation rules, and beat placement from words.json.
---

# VO pipeline

**VO comes first.** The voice is generated before any visual timing exists;
everything downstream (comp timelines, section durations) is derived from it.

## Generating VO — `gen_vo.py`

Each project's `build/<project>/<cut>/gen_vo.py` (copied from
`references/gen_vo_template.py`) holds the SPEC: a dict mapping
`"secN/vo/p1"` to an alternating list of **breath groups** (strings) and
**gaps** (floats, seconds of pause after the preceding group).

- A breath group is one phrase the voice reads in a single go. Split where a
  human would breathe; a full sentence is usually 1–2 groups.
- Kokoro `af_sky` at speed `0.80` via `npx hyperframes tts`.
- The template already handles: silence trim keeping 80 ms head / 150 ms tail,
  0.1 s reversed tail fade (no hard gating), gaps shrunk by the 0.23 s kept
  margins, 120 ms head delay + 0.3 s tail pad.
- **Idempotent:** existing `secN/vo/p1.wav` files are skipped. To regenerate a
  section's VO, delete its wav. To fork a cut cheaply: copy the whole build
  tree, delete only the changed sections' derived files, rerun.
- **Never** apply adaptive loudnorm to these gappy clips — level is set at mux
  time with measured static gain (see `mix-master`).

## Pronunciation rules

- **Rephrase, never respell.** Kokoro's G2P collapses respellings of plural
  heteronyms — "livz", "livs", "lyvz" all render identically to "lives"
  (/laɪvz/), and IPA markup gets read aloud. If a word reads wrong, choose a
  different word ("lives" → "runs").
- Hyphenate initialisms so they're spelled out: "A-I", "S-D-K", "D-L-P".
- Spell tricky brand names phonetically in the VO text (e.g. "Tilly-cho" for
  a name spelled Tilicho) — the phonetic form goes only in the SPEC, never on
  screen.
- Listen to every regenerated group before using it; heteronyms and unusual
  names are the usual offenders.

## Word timestamps — `whisper_words.py`

```bash
python3 whisper_words.py secN/vo/p1.wav secN/words.json
```

- Runs faster-whisper `base.en` with `device='cpu'`, `compute_type='int8'` —
  required where libcublas/CUDA is absent, and fast enough anyway.
- Output: `[{"word": ..., "start": ..., "end": ...}, ...]`.
- Mis-transcriptions ("Pass Finder" for "Pathfinder") are harmless — only the
  timings are consumed; the audio itself is correct.

## Placing beats

A visual beat lands at **word start + 0.3 s** — the 0.3 s is the `adelay=300|300`
mux lead applied in `mix-master`, so comp-time and final-audio-time line up.

Find the word that should trigger the beat in `words.json`, add 0.3, and use
that as the timeline position in the comp.

## The retime loop (when VO text changes)

1. Record the change in a new `script/vN.md` (rule 3).
2. Edit the SPEC in `gen_vo.py`; delete the affected `secN/vo/p1.wav`; rerun.
3. Rerun `whisper_words.py` for that section.
4. **Rewrite the comp's timeline block wholesale** to the new word times —
   never sed/patch individual time literals in place; generic replacements hit
   wrong lines and corrupt the timeline silently (see `comp-craft`).
5. Re-render, re-mux, re-verify the changed beats by eye.
