---
name: video-studio
description: Use for any video-studio work — making, editing, forking, or shipping a narrated product video, pitch video, explainer, launch or demo film; starting a new video project or a new cut for a different client; organizing video inputs, scripts, versions, or deliverables. Entry point that defines the workspace folder system, the six working rules, the design.md override convention, and routes to vo-pipeline (voiceover + timing), comp-craft (composition + animation), and mix-master (audio mux + mastering).
---

# Video Studio

## Mandatory, automatic — never wait to be asked

Whenever this skill is active (any video, any cut, any single scene edit), the following
load in this order **before the first comp line is written**, without the user asking:

1. `comp-craft/references/smooth-motion.md` — the method (current → vector ledger →
   sustained-motion routes → helpers → causal motion → seams) and the nine test gates.
2. `comp-craft/references/motion.md` — the seam helpers to paste into every timeline.
3. `comp-craft/references/visual-qa.md` — the eye gate: nothing renders unseen.
4. The bundled `motion-doctrine` skill (and `cut-the-curve` when writing seam tweens,
   `seam-craft` when assembling, `oversized-cursor` for any UI scene).

The user never has to say "make it smooth", "check it visually" or "use the motion
skill". Those are the default behaviour of this plugin. Shipping a film that pops
in/out at cuts, idles, or contains placeholder-grade visuals is a plugin failure, not a
style choice. If a step is skipped for speed, say so explicitly in the ship README.

You build narrated product videos through an **audio-locked pipeline**: the
voiceover is generated first, word timestamps are extracted from it, and the
visuals are timed to the words — never the other way around.

```
script/vN.md ──► gen_vo.py ──► vo/p1.wav ──► whisper ──► words.json
                                                             │
comp/index.html timeline retimed to words ◄──────────────────┘
      │
      ▼
lint ► check ► SNAPSHOT + read every frame by eye (fix, repeat) ► render
      │
      ▼
frame-verify render ► seam sheets (secN last 3 | secN+1 first 3) ► mux VO (secN.mp4) ──► concat ──► bed ──► master ──► contact sheet ──► ship
```

Motion is designed before timelines are written: pick the film's current, write the
vector ledger for every cut, assign a sustained-motion route to every phase
(`comp-craft/references/smooth-motion.md`). The eye gates are not optional.

## Workspace layout

Every project lives in four top-level folders (scaffolded by `/video-new`):

```
<workspace>/
├── context/<project>/             # every textual input, moved here BEFORE use
│   ├── BRIEF.md                   # what the video is, audience, length budget
│   ├── design.md                  # OPTIONAL — project design system (see below)
│   ├── <dated pasted docs>.md     # e.g. 2026-09-07-narration-v3.md
│   └── feedback/
│       └── YYYY-MM-DD-<who>.md    # each review round, verbatim
├── assets/<project>/              # every binary input the user drops
│   ├── logos/  screenshots/  recordings/  data/
├── build/<project>/<cut>/         # ONE live scene tree per cut
│   ├── script/
│   │   ├── v1.md v2.md …          # full VO text + beat sheet + changelog per version
│   │   └── CURRENT.md             # one line naming the current script version
│   ├── sec1/ … secN/
│   │   ├── comp/index.html        # SOURCE — the GSAP composition
│   │   ├── vo/p1.wav              # derived
│   │   ├── words.json             # derived
│   │   ├── comp.mp4               # derived (silent render)
│   │   └── secN.mp4               # derived (muxed section)
│   ├── gen_vo.py                  # SOURCE — VO SPEC lives here
│   ├── gen_bed.py                 # source (from template)
│   ├── list.txt  bed.wav  final.mp4  # derived
└── videos/<project>/
    ├── current/
    │   ├── <Project>-vN.mp4           # latest batch (may be several cuts)
    │   └── README.md                  # from references/readme-template.md
    └── versions/                      # every previously shipped mp4, never deleted
```

## Design system

Every visual decision (palette, type, marks, voice) comes from **one** design
doc, resolved in this order:

1. `context/<project>/design.md` — a design file the user supplies for their
   project. If the user hands you any design/brand doc, save it there (rule 1)
   and use it for ALL visuals in that project.
2. `references/design-default.md` — the built-in default, used whenever the
   project has no design.md.

A project design.md should cover the default's headings (Palettes, Type,
Marks, Voice); anything it omits falls back to the default. Never mix the two
within a project beyond that fallback.

**Cuts:** the default cut is `main/`. A fork for a different client or framing
gets its own cut directory (e.g. `gcp/`, `migration/`) — created by copying an
existing cut's tree and deleting only the changed sections' *derived* files;
the VO generator's skip-if-exists behavior regenerates only what's missing, so
untouched sections stay byte-identical.

## The six rules

1. **Move-in rule.** Any input the user pastes or drops — doc, Slack thread,
   screenshot, recording, spreadsheet — is saved into `context/<project>/`
   (text) or `assets/<project>/` (binary) with a dated, descriptive name
   **before** it is used. Never work from a loose file in the repo root or
   from chat scrollback.
2. **Ship rotation.** On every ship: move the previous `current/` mp4(s) to
   `versions/`, place the new deliverable(s) in `current/`, rewrite
   `current/README.md` from `references/readme-template.md`. `versions/` is
   append-only.
3. **Script versioning.** Every VO or visual change produces a new
   `script/vN.md` (full VO + beat sheet + "changed since vN−1" list). Comps
   are never edited without the script recording why. The doc drives the
   edit, not the other way round.
4. **Source vs derived.** Source-of-truth: `comp/index.html`, the `gen_vo.py`
   SPEC, `script/*.md`, everything in `context/` and `assets/`. Derived (safe
   to delete, regenerated by the pipeline): wavs, `words.json`, renders,
   muxed sections, `bed.wav`, `final.mp4`.
5. **Audio-locked order.** VO first; whisper word timestamps second; the comp
   timeline retimed to the words last. Timeline edits are whole-block
   rewrites — never sed/patch bare time literals.
6. **Craft gates.** Visual QA before render: every beat snapshotted and read by eye at
   full size, every placeholder-grade element fixed, then render, then frame-verify again
   (`comp-craft/references/visual-qa.md`). Flow: every cut obeys the seam law and nothing idles
   (`comp-craft/references/motion.md`). Show-don't-tell (on-screen copy never prints the VO
   sentence); privacy-mask real names/paths visible in recordings; verify
   every changed beat by eye from rendered frames before shipping;
   `npx hyperframes check` gates (runtime, layout overlap, motion, WCAG
   contrast) must pass — mid-tween contrast warnings on animating elements
   are acceptable when both end states pass.

## Routing

| Topic | Go to |
|---|---|
| VO text, breath groups, pronunciation, whisper, word timings, retiming | `vo-pipeline` skill |
| Composition HTML, GSAP timelines, beats, layout, checks, rendering | `comp-craft` skill |
| Transitions, seams between sections, flow, eases, "it feels stuck" | `comp-craft` → `references/smooth-motion.md` (method + tests), `references/motion.md` (helpers), then `motion-doctrine` / `cut-the-curve` / `seam-craft` / `oversized-cursor` skills (full doctrine, bundled) |
| Pre-render visual check, placeholder-looking elements, "this looks cheap" | `comp-craft` → `references/visual-qa.md` |
| Section mux, gain, concat, music bed, ducking, mastering, loudness | `mix-master` skill |
| Colors, fonts, watermark, lockup, voice | `context/<project>/design.md`, else `references/design-default.md` |
| Deep HyperFrames comp authoring | the `hyperframes` skill family **if installed**; otherwise `comp-craft` is sufficient |

## Environment notes

- WSL: `export PATH=$HOME/.nvm/versions/node/<ver>/bin:$PATH` before node/npx;
  Windows-mounted paths are slow for many-small-file ops — fine at this scale.
- faster-whisper must run `device='cpu'` where libcublas is absent.
- Render comps one at a time with `-w 2` (memory).
- `ffmpeg -ss` output seeking is not frame-exact — use `trim=` filters and
  always-on masks for privacy blurs.
