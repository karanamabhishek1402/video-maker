# Visual QA — the gate BEFORE render (and again after)

The failure this prevents (2026-10-09, gemini-launch v2): a film rendered and shipped with
placeholder-grade elements the author never looked at closely — straight lines with a
detached white dot as "light trails", unicode glyphs and bare circles as icons, a pale
flat send button, white blob pills with coloured squares as "3-D icons", a flat triangle
as a paper plane. Lint, check and seam gates all passed. Only eyes catch this.

**Rule: nothing is rendered to mp4 until every beat has been snapshotted, read by eye
at full size, compared against the reference or the design intent, and corrected.
Render is the last step, not the first look.**

## 1. Snapshot every comp before rendering

```bash
npx hyperframes snapshot secN/comp --at <t1,t2,…> -o secN/snapshots          # key beats
npx hyperframes snapshot secN/comp --at <…> --against <reference.mp4>        # recreation work: render|reference pairs
npx hyperframes snapshot secN/comp --at <t> --zoom '#element'                # any element you are unsure of, at 3× density
```

Pick times at: the first frame, every entry's landing, every mechanism mid-flight, every
cut ± 0.1 s, and the last frame. Read every PNG with the image tool at full size — do not
read a 6-up contact sheet and call it verified; small tiles hide every defect listed below.

## 2. What to look for (each of these shipped once — never again)

| Looks like | It is | Fix |
|---|---|---|
| A straight line with a round white dot at the end | not a light trail | curved path, tapered gradient, wide blurred glow underlay, head = soft radial bloom in the trail's colour, moving as one comet segment |
| A unicode character (⌂ ⚙ ◆ ▶) or a bare circle/square standing in for an icon | a placeholder | inline SVG icon paths (doc, clock, search, list…) or brand artwork; for app tiles, real logos or honest simplified marks |
| A pale tinted circle with a thin arrow | not a send button | solid brand-blue disc, bold white arrow, soft shadow |
| White oblong pills with flat coloured squares | not "3-D icons" | circular discs with radial sheen + large halo, SVG glyphs with gradient fill and a white highlight overlay, drop shadow |
| A flat single-colour triangle | not a paper plane | three faces (light wing, mid wing, dark fold), gradients, a white edge highlight, double glow; banks along the path |
| Text at 15–35 % opacity sitting behind the current claim | a ghost pre-entry state | hide until its entry frame (`opacity:0` at 0, reveal-set at t) |
| A blank first frame, or a frame where nothing moves | a dead beat | seam/entry per `motion.md` |
| An element that is "fine at thumbnail size" | unverified | zoom-snapshot it |

Ask of every element: *would this pass in the reference film, at full screen, paused?*
If the answer is "it's a placeholder for now", it is not done.

## 3. Order of operations (hard)

1. Author the comp.  2. `lint` + `check`.  3. **Snapshot + read + compare + fix, loop
until every beat passes by eye.**  4. Only then `render`.  5. Frame-verify the render at
the same beats (renders can differ from snapshots: cold-seek states, motion-path timing).
6. Seam sheets between sections (`motion.md` §3).  7. Assemble, mux, ship.

A render made before step 3 is not a preview — it is a wasted render and a shipped
defect waiting to happen.

## 4. Motion stability test (jitter) — run on the RENDER when anything "shakes"

Snapshots cannot show jitter; only consecutive render frames can. Two tweens on the same
property of one element (e.g. an entrance tween still running when a relative `x:'-=60'`
drift starts) produce a fast left/right shake that reads as a glitch. Test it, don't guess:

```bash
ffmpeg -v error -y -i secN/comp.mp4 -vf "select='between(t,T0,T1)',fps=30,crop=W:H:X:Y" jit/f%03d.png
python3 - <<'EOF'
import glob;from PIL import Image;import numpy as np
fs=sorted(glob.glob('jit/f*.png'));prev=None;out=[]
for f in fs:
    a=np.asarray(Image.open(f).convert('L')).astype(int)
    if prev is not None: out.append(round(float(np.abs(a-prev).mean()),2))
    prev=a
print(out)   # once the element has landed, every value must be ~0.00-0.02; spikes = jitter
EOF
```

Crop to the element's landed position; a monotonic decay to zero is a clean landing. Any
oscillation after landing is a defect — find the second tween on that property (grep the
selector), move drifts to a parent container, and re-test on a fresh render.
