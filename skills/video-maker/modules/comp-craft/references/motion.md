# Motion — the flow rules (read before authoring any timeline)

The failure these prevent: scenes authored in isolation. Every element pops in from rest,
settles, the frame goes dead, then a hard cut to the next scene which pops in again. The
eye's momentum dies at every seam and the film feels stuck. The fix is not softer eases —
it is matched VECTORS across every cut and something always mid-flight.

## 1. The seam law (every cut, inside a comp or between secN files)

> How A exits decides how B enters: same axis, same direction, matched speed, cut
> mid-motion on BOTH sides.

- **One current per film.** Default LEFT. Every ordinary cut rides it. Other vectors are
  spent on meaning: UP = a conclusion rises; Z-push (growing) = deeper into the same
  thought; Z-pull (shrinking) = ARRIVAL, something bigger lands; scale-burst = leaving a world.
- **Z is a sign.** Across a Z cut, d(scale)/dt must have the same sign on both sides.
  A shrinking exit answered by a grow-from-small entry is the most common violation
  (grow-from-small is the default element entrance — do not use it after a pull).
- **A direction change needs a cause** (a click, an impact, a chapter boundary) — else
  it reads as ping-pong.
- **Never crossfade** two scenes. A crossfade has no carrier.

## 2. The four moves (parameters)

| Move | When | Exit | Entry |
|---|---|---|---|
| **Cut-the-curve** (default boundary) | scene → scene, text → surface | `x: 0→−230` `power4.in` 0.34 s; opacity →0 linear ~0.3 s | `x: +230→0` `power4.out` 0.3–0.4 s from opacity 0.35 |
| **Zoom-through** (push) | headline → headline, deeper into the thought; after a click | `scale 1→1.2`, blur 0→10 px, 0.2 s `power3.in`; opacity →0 as its own linear tween | `scale .75→1`, blur 10→0, opacity .15→1, 0.5 s `expo.out` |
| **Inverse zoom** (pull) | an arrival / payoff / end card | `scale 1→.8`, blur 10 px, 0.2 s | `scale 1.25→1`, blur 10→0, 0.5 s `expo.out` |
| **Rack-focus blur-cut** | the ONE visible cut per ~8 s, same surface, state swap | stays opaque; blur to 8–12 px, `power2.in` | from the same blur, `power2.out`, ≥ exit duration |

Blur: 10 px for text-scale subjects, 18–20 px for a full-frame surface (card, app, stage).
Blur the wrapper, never children. Partial travel only (~12 % of frame) — never full off-screen.

Helpers to paste at the top of every timeline (and keep identical across comps):

```js
const EXIT=(s,t,d=.34)=>tl.to(s,{x:-230,duration:d,ease:'power4.in'},t).to(s,{opacity:0,duration:d*.9,ease:'none'},t);
const ENTER=(s,t,d=.4)=>tl.set(s,{x:230,opacity:.35},0).to(s,{x:0,opacity:1,duration:d,ease:'power4.out'},t);
const ZOUT=(s,t,b=10,d=.2)=>tl.to(s,{scale:1.2,filter:`blur(${b}px)`,duration:d,ease:'power3.in'},t).to(s,{opacity:0,duration:d,ease:'none'},t);
const ZIN=(s,t,b=10,d=.5)=>tl.set(s,{scale:.75,opacity:.15,filter:`blur(${b}px)`},0).to(s,{scale:1,opacity:1,filter:'blur(0px)',duration:d,ease:'expo.out'},t);
```

## 3. Seams between secN files (our concat pipeline)

Sections are rendered separately and concatenated, so a seam is the last frame of secN
and the first frame of secN+1. Author both halves:

- secN: the hero's EXIT starts at `duration − 0.34` and is still moving on the last frame.
  Never fade to black or settle to rest before the cut (the opening of the film and the
  end card are the only exceptions).
- secN+1: the hero is ENTER'd at `t = 0` — a `tl.set(..., 0)` places it at `x:+230`,
  opacity .35 on frame 0, then `power4.out` to rest. The surface (light/dark background)
  hard-cuts; the hero carries the eye.
- Z seams: match the sign. A click at the end of secN pushes the surface through camera
  (scale ↑, blur 18, fade) → secN+1 opens with its hero growing (`ZIN` on a stage wrapper).
- Verify by eye: extract the last frame of secN and the first frame of secN+1 and read them
  side by side — the hero must be mid-travel on both.

## 4. The scene keeps performing

- **No idle wobble.** Breathe/float/glow-pulse loops are banned. If a scene has seconds
  left after its entries, add story: staged reveals on beats, a camera path (scale+pan
  with intent), sequenced UI life (a cursor, a typed line, a progress state), or an
  animated sequence. Test: pause at any second, something meaningful is mid-flight.
- **Causal motion.** Click → squash → release → flight → impact → reveal. The reaction
  starts ON the causing frame, never "shortly after".
- **Stillness before climax.** 0.3–0.75 s between the action and its payoff.
- **Entries.** Single entry ≤ 0.8 s; a long build is a stagger, not one slow tween.
  Cascades: `power4.out`, items overlap (next starts as the previous lands), gaps shrink,
  total stagger ≤ 0.5 s; heavy anchors travel 60–80 px, light words 30–48 px.
- **Eases.** Exits `power4.in` / `power3.in`; entries `power4.out` / `expo.out`. Never
  `.inOut` on either side of a cut; never `bounce` / `elastic`. Similar elements share one
  ease+duration.
- **Budget.** 2–3 transition types per film, repeated. Reserved vectors are not variety.

## 5. Lint gates that bite (HyperFrames)

- `gsap.utils.random` → non-deterministic; use fixed arrays.
- animating `letterSpacing` / `width` / `top` → reflow; stack two copies and crossfade/scale.
- a hidden element's `fromTo` must put `opacity` in the destination vars.
- two `fromTo`s on one target → `immediateRender:false` on all but the earliest.
- changing a background colour mid-tween trips the contrast gate → use `tl.set` for the
  colour and tween only the scale.
