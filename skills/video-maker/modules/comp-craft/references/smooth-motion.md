# Smooth motion — how to use the motion skills in this plugin (the working method)

Four skills ship in this plugin and together make a film flow instead of stutter:

| Skill | What it decides | Read it when |
|---|---|---|
| `motion-doctrine` | The LAW: vector-matched seams, one current, no idle wobble, causal motion, the seam gate | before composing ANY timeline — it decides what happens at every cut |
| `cut-the-curve` | The PARAMETERS: zoom-through, inverse zoom, cut-the-curve, waterfall cut/entry, rack-focus, nudge curve | when writing the actual tweens for a seam, a text handoff, an arrival cascade or a group slide |
| `seam-craft` | The RENDER mechanics: opaque stage ground, white-flash guard, how overlapping wrappers composite | when assembling, or when a cut flashes white / shows through |
| `oversized-cursor` | Cursor-led action: the off-screen entry law, tip targeting, click ignites the next beat | any UI scene, any scene that reads static |

Short versions of the rules live in `motion.md` (seams + helpers) and `visual-qa.md`
(the eye gate). The full skills are the source of truth; this page is the method.

## The method, in order

1. **Pick the current.** One direction for the whole film (default LEFT). Write it at the
   top of `script/vN.md`. Every ordinary cut rides it; UP / Z-push / Z-pull / scale-burst
   are spent on meaning only (`motion-doctrine` → The Current).
2. **Write the vector ledger before any timeline.** One row per seam — inside a comp and
   between secN files: cut time, exit vector (axis + sign), entry vector, carrier element,
   technique. If exit ≠ entry, fix the plan, not the ease. For our multi-file pipeline the
   ledger lives in `script/vN.md` as a table; for a single-file HyperFrames master, use
   `ledger.json` + `motion-doctrine/scripts/seam-stamp.mjs`.
3. **Assign a sustained-motion route to every phase** between entry and exit: staged
   reveals · camera with intent · sequenced UI life · animated sequence · cursor-led
   action. Name it in the beat sheet. "Hold" is not a route.
4. **Author with the helpers.** Paste `EXIT / ENTER / ZOUT / ZIN` from `motion.md` into
   every comp unchanged. Entries `power4.out`/`expo.out`, exits `power4.in`/`power3.in`,
   never `.inOut` across a cut, never `bounce`/`elastic`. Cascades per `cut-the-curve` §6
   (overlap, shrinking gaps, weight-scaled travel). Group slides per §7 (nudge curve).
5. **Make motion causal.** A click/impact starts its reaction ON the same frame. A
   direction change needs that cause; otherwise it is ping-pong.
6. **Stillness before climax.** 0.3–0.75 s between the action and its payoff.
7. **Seam the files.** secN's hero exits still moving on its last frame; secN+1's hero is
   mid-flight on frame 0 (`tl.set` at 0 to the pre-entry state, reveal-set at t). Z seams
   match the sign (`motion.md` §3).

## The testing part — mandatory, in this order

| # | Gate | Command / action | Pass condition |
|---|---|---|---|
| T1 | Structure | `npx hyperframes lint secN/comp` | 0 errors |
| T2 | Runtime, layout, motion, contrast | `npx hyperframes check secN/comp` | 0 errors; mid-tween contrast samples on animating elements are the only tolerated flags |
| T3 | **Visual QA (before render)** | `npx hyperframes snapshot secN/comp --at <beats>` (+ `--against <reference>` when rebuilding, `--zoom '#el'` for anything doubtful); read every PNG at full size | no placeholder-grade element (`visual-qa.md` §2), no ghost states, no blank frames, every beat reads like the reference |
| T4 | Render | `npx hyperframes render secN/comp -o secN/comp.mp4 -w 2` | only after T3 passes |
| T5 | Frame-verify the render | extract frames at the same beats; read at full size | matches T3; cold-seek states and motion-path timing can differ from snapshots |
| T6 | Seam sheets | last 3 frames of secN beside first 3 of secN+1 (`motion.md` §3) | hero mid-travel on both sides; no blank frame 0; no dead gap |
| T7 | Internal cuts | frames at cut −0.1 / 0 / +0.13 / +0.4 for every in-comp cut | same as T6 |
| T8 | Single-file projects | `node motion-doctrine/scripts/seam-gate.mjs verify --ledger ledger.json --project .` | exit 0 |
| T9 | Assembly | concat → mux → `loudnorm` measure | −16 … −18 LUFS, TP ≤ −1.5 dBTP; full-film contact sheet read once more |

Any edit to a scene's first or last second re-opens T3, T5 and T6 for that boundary.
A gate that was skipped is a defect that will ship — this has happened; don't repeat it.
