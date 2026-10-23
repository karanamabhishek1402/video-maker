---
description: Master the final video, rotate current→versions, write the README, deliver the mp4
argument-hint: <project> [cut]
---

Ship project `$1`, cut `$2` (default `main`). Work in `build/$1/<cut>/`.
Follow the `mix-master` skill for every audio step. Checklist — execute in
order, stop on any failure:

1. **Gates:** every section has a muxed `secN/secN.mp4`; every changed comp
   passed `npx hyperframes check` and its changed beats were frame-verified
   by eye. If a section's mux is stale (comp or VO newer than secN.mp4),
   re-mux it first.
2. **Concat:** write `list.txt` (all sections in order), concat with
   `-c copy` → `joined.mp4`; ffprobe its exact duration.
3. **Bed:** `python3 gen_bed.py <exact duration>` — always regenerate at the
   new duration, never reuse.
4. **Master:** run the mix-master §3 filter chain → `final.mp4`.
5. **Loudness check:** verify ≈ −16.9 LUFS integrated / ≤ −3.8 dBTP via
   loudnorm print. Outside −16…−18 LUFS: adjust the final `volume=` only.
6. **Name and place:** determine the next version number N (look at
   `videos/$1/current/` and `versions/`). Copy `final.mp4` →
   `videos/$1/current/<Project>-vN.mp4` (CamelCase project; for
   non-main cuts: `<Project>-<Cut>-vN.mp4`).
7. **Rotate:** move the PREVIOUS version's mp4(s) from `current/` to
   `versions/` (append-only — never delete or overwrite there).
8. **README:** rewrite `videos/$1/current/README.md` from
   `<skill-dir>/modules/video-studio/references/readme-template.md`,
   referencing the script version and the feedback docs that drove the changes.
9. **Record:** add the changelog entry to `build/$1/<cut>/script/vN.md` if
   not already written (rule 3), and update `script/CURRENT.md`.
10. **Deliver:** hand the user the new mp4 (send the file if the session
    supports it; otherwise give the full path) with a one-line summary:
    duration, loudness, what changed.

Before rotating and shipping, confirm the gates in `comp-craft/references/smooth-motion.md` (T1–T9) ran for every changed section, and that `visual-qa.md` was applied to every beat. If any gate was skipped, say so in the README under a 'Gates skipped' line — never silently.
