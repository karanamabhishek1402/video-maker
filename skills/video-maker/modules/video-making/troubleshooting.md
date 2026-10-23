# Troubleshooting — failures observed in production

Every entry here cost real time. Scan this before debugging from scratch.

---

## Rendering

**Renders OOM-killed (exit 137) when run back to back.**
Each Hyperframes worker is a Chrome process. Rendering several compositions in one loop with default `-w auto` exhausts memory and the shell dies mid-loop.
→ Render one composition per command, `-w 2`. Check which outputs exist before assuming a batch finished.

**`hyperframes lint index.html` fails with "Not a directory".**
→ `lint` and `check` take a **directory**: `npx hyperframes lint .`

**Lint: `missing_timeline_registry` / `gsap_timeline_not_registered`.**
→ The renderer drives your GSAP timeline; it must be published:
```js
window.__timelines = window.__timelines || {}; window.__timelines["main"] = tl;
```

**`check` fails on contrast (e.g. 2.58:1, needs 3:1).**
Muted greys that look fine in a browser fail against an off-white background.
→ Darken the token (`#a39c92` → `#78726b`). Fix globally; the same grey is usually reused.

**Some glyphs render at small-cap height in an ALL-CAPS label.**
A long `text-transform: uppercase` string rendered `r`, `i`, `a` visibly shorter than its neighbours while other labels in the same file were fine.
→ Type the string in literal capitals in the HTML; don't rely on the transform.

**It recurs, and it is not predictable from the string.** Fixing only the label you were shown guarantees another report. On the first sighting, sweep the whole project:

```bash
# every class that sets text-transform: uppercase, per composition
grep -oE '^\s*\.[a-zA-Z0-9 .>-]+\{[^}]*text-transform: uppercase[^}]*\}' comp-*/index.html | sed -E 's/\{.*//'
```

Then convert the text of elements using those classes to literal capitals. **Match on the full selector, not the last class name** — a bare `.sub` or `.c1` also matches `.defend .sub` and `.row .c1`, which are NOT uppercase-transformed, and blindly uppercasing them shouts body copy and data rows. Re-read every replacement before rendering.

**Fonts substituted at render time** (`'Menlo' → JetBrains Mono`).
→ Informational, but preview and render differ. Name the target font directly if it matters.

## Generated art

**The model drops or replaces the payoff object.**
"A phone face-down on a desk" came back as a notebook; "a wall of names" came back as a
surreal double-portrait. The composition is beautiful and wrong.
→ Read every frame against its shot intent before animating. State the object twice and
negatively ("No notebook"), regenerate only the rejected frames.

**Character drifts between frames.**
Same prompt, different woman.
→ One character sheet, generated first, passed as a reference image to every frame,
plus "the same woman as the reference sheet". Pin anything the sheet leaves ambiguous
("no glasses" — one sheet view had them).

**Garbled text on props** (lists, whiteboards, posters).
Image models write readable-garbage English that destroys credibility in close-up.
→ Prompt "illegible handwriting-like marks" AND "no text anywhere in the image"; expect
it to write anyway; judge at final resolution — soft garble in motion passes, legible
garble does not. Real captions are ALWAYS composited in the edit, never generated.

**AI Studio (`generativelanguage.googleapis.com`) key generates text but every image
model 429s with `free_tier ... limit: 0`.**
Image generation has no free tier — that is policy, not quota exhaustion; no model name
routes around it.
→ Either paid tier on the key, or **Vertex AI on a GCP project** with gcloud bearer auth
(`aiplatform.googleapis.com`, model `gemini-3.1-flash-image`). Vertex requires
`"role":"user"` on contents — omitting it is a 400.

**gcloud in WSL says "No credentialed accounts" though the user is logged in.**
The Windows SDK reads the Linux config dir when invoked from WSL.
→ `export CLOUDSDK_CONFIG="/mnt/c/Users/<user>/AppData/Roaming/gcloud"` — and never run
`gcloud auth login` in WSL (no browser; it hangs forever on a loopback server).

## WSL / cross-platform

**A large model file downloads fine on `/mnt/c/...`, verifies, then VANISHES minutes later.**
Windows Defender quarantines big opaque binaries on the Windows filesystem (a 466 MB
whisper ggml disappeared after passing its magic-header check).
→ Keep models and built tools on the WSL filesystem (`~/tools/...`). whisper.cpp builds
natively in ~2 min (`cmake -B build && cmake --build build -j12`); `npx hyperframes
transcribe` reporting `whisper_unavailable` means ITS Windows-side copy is missing — a
native `whisper-cli -ml 1 -oj` wrapper produces the same word-level JSON.

**`-o /mnt/c/...` silently writes to `C:\mnt\c\...`.**
`npx` resolves to Windows node, which does not understand WSL paths, so it creates a literal directory of that name.
→ Pass native Windows paths to Hyperframes: `-o 'C:\Users\...\out.mp4'`. Read/write with WSL paths everywhere else.

**Filenames with unusual whitespace** (screen recordings often contain a narrow no-break space before "PM").
→ Match with a glob (`./Screen*5.40*.mov`), never by retyping the name.

## ffmpeg

**`Stream specifier 'v' in filtergraph matches no streams`.**
A filter output was named `[v]`, which ffmpeg parses as "the video stream" in some
positions — and the same graph consumed one labelled stream twice.
→ Never name labels `[v]`/`[a]`-ambiguous things; a stream feeding two filters must be
`asplit` first (`[0:a]asplit=2[vox][key]`).

**A PNG overlay with a delayed `fade` never appears.**
A bare image input is a single frame at `t=0`, so `fade=st=28.3` never fires — the overlay stays at alpha 0.
→ Turn it into a stream first:
```
[5:v]...,loop=loop=-1:size=1,setpts=N/30/TB,fade=t=in:st=0:d=0.6:alpha=1,setpts=PTS+28.3/TB[x]
```

**A logo is invisible over dark footage.**
Ink-coloured wordmarks vanish on dark UI.
→ Keep a light variant and swap by window:
```
[b][ge]overlay=54:46:enable='not(between(t,0,10.4))'[a];
[a][gel]overlay=54:46:enable='between(t,0,10.4)'[v]
```

**Supplied logo assets are rarely usable as-is.**
A `.webp` wordmark may be white (invisible on light backgrounds); a `.jpg` has no transparency.
→ Isolate the usable glyph (`crop`), key out a flat background (`colorkey=0x000000:0.30:0.05`), typeset the wordmark yourself in the video's ink colour. Composite the result over the actual background colour and look before using it.

**A badge floating over UI text is unreadable.**
→ Seat it on a plate: `drawbox=...:color=0xffffff@0.95:t=fill` then a 3px border box, both gated by the same `enable`.

**`vstack`/`hstack` fail: "width does not match".**
→ Scale every input to a common width first.

**`astats` prints nothing** under `-v error`.
→ It logs at info level: `-hide_banner -nostats -loglevel info`, or use `volumedetect`.

## Audio

**Music stops partway through and the ending is silent.**
The bed is simply shorter than the video — invisible until the edit grows past the track length.
→ Check `ffprobe` on the track vs the final. Extend by crossfading the track into a repeat of itself:
```bash
ffmpeg -i track.mp3 -i track.mp3 -filter_complex "[0:a][1:a]acrossfade=d=4:c1=tri:c2=tri[a]" -map "[a]" bed_long.mp3
```
A hard `-stream_loop` leaves an audible seam; the crossfade leaves a ~4 dB dip that is inaudible under narration.

**Narration sounds flat and rushed in places.**
→ For Kokoro-style single-line models: split phrases, vary speed. For paragraph-capable
models (Sarvam bulbul): regenerate the whole paragraph — do NOT fall back to stitching.

**A list read as separate clips sounds "beaky"/choppy.**
Four cold-started one-word clips have four unrelated prosodies.
→ One continuous read of the entire list plus its closing line, then retime the visuals
to its word timestamps. The voice is the clock; the cards bend to it.

**Cycled cards pair with the wrong outcome.**
With staggered in/out offsets, item N's card overlaps item N−1's result on screen.
→ Derive each card's out-time from the NEXT item's word timestamp; verify with frames
extracted mid-cycle, not at boundaries.

**TTS output is effectively clipping** (true peak −0.2 dBTP at normal loudness).
→ `loudnorm` every element at section mux (dialogue I=-18:TP=-1.5), and a final
`alimiter` on the master. Check with `loudnorm=print_format=json`, not by ear.

**Single-pass `loudnorm` on quiet material overshoots** (asked −27, got −22).
→ For fixed relative levels use plain `volume=XdB` gain staging instead; reserve
loudnorm for dialogue-level elements.

**A word is mispronounced.**
→ Respell phonetically in the TTS input (`lives` → `livz` for the verb). Re-record that one phrase; if the duration is close, no retiming is needed.

## Process

**Session dies mid-build and work is lost.**
→ Every step idempotent and skip-if-exists, all artefacts on persistent storage. Never `/tmp` — it gets wiped.

**A repo hook blocks writes** (e.g. protected branch) even for files outside the repo.
→ Switch to a scratch branch before writing, switch back after. Expect it to block plan/memory files too.

**A stakeholder claim outruns the documentation.**
Narration asserted a deployment/security posture that the accepted ADR contradicted.
→ Grep the repo for the claim (ADRs, tickets, open-decisions) before recording it. Report the conflict, offer wording backed by what is actually true, and let the owner choose. Note in the script doc which claims still need sign-off.

**Numbers on screen contradict numbers in the footage.**
Illustrative figures in cards vs real pilot data in recordings.
→ Either label the footage, frame shots to avoid raw counters, or reseed and re-record. Decide explicitly rather than hoping nobody notices.
