# Pipeline — step by step

Assumes `hyperframes` (via `npx`), `ffmpeg`/`ffprobe`, and a working dir `$V` on persistent storage.

---

## 0. Install the official Hyperframes skills first

```bash
npx hyperframes skills     # installs version-matched skills (hyperframes-core, motion-doctrine, …)
```

**Read `hyperframes-core` before writing any composition.** The contract points that
contradict habits formed without it:

- The timeline must be **`gsap.timeline({ paused: true })`** — never autoplay.
- Root carries `data-start="0"` alongside id/width/height/duration.
- A full-screen fill goes on a **full-bleed child** (`position:absolute; inset:0`),
  never on the root — the producer can drop the root's own background (frame renders black).
- **No `repeat: -1`, no `Math.random`, no `Date.now()`** — and no GSAP
  `stagger: { from: "random" }`: with 2 render workers each loading the page separately,
  they pick different orders and the scene JUMPS at the worker boundary.
- **Every asset the comp references must live inside the comp's own directory** —
  the renderer serves only that directory; `../../art/x.png` lints as missing. Copy files in.

Also in the CLI, replacing manual steps: `check` (all gates), `snapshot --at t1,t2`
(visual verification), `transcribe` (needs whisper — see troubleshooting).

## 1. Script — one row per breath

Write the script as a table, one row per phrase, before generating anything:

| id | speed | line |
|---|---|---|
| q01 | 1.00 | Institutions everywhere are rolling out Gemini Enterprise. |
| q02 | 1.05 | Thousands of licenses, handed out in a single week. |

Rules:
- One row = one breath = one visual beat. If a line carries two ideas, split it.
- **1.00 for emphatic lines, 1.05 for connective ones.** Uniform speed sounds robotic.
- Punctuation is pacing direction: `...` for a beat, `—` for a turn.
- Phonetic respellings go in the TTS input only, never in the on-screen copy.
- Budget ~150 wpm plus gaps. 450 words ≈ 3:20 finished.

## 2. Narration — paragraph reads, not stitched phrases

Generate **one wav per section, containing the whole paragraph**. The TTS model's own
prosody carries sentence-to-sentence flow; stitching one-line clips with silence files
produced audibly robotic reads and dead stops a stakeholder called out ("beaky",
"stops for a few seconds"). The phrase-bank approach (`scripts/tts-bank.sh`) survives
only for single-line pickups and diegetic character lines.

- To fix one line, regenerate the paragraph — reads are cheap; robotic joins are not.
- **Rapid list sequences** (cards cycling to names): ONE continuous read of the whole
  list including its closer, then retime the visuals to its word timestamps.
- Sarvam bulbul:v3 (en-IN + Indic languages): `POST https://api.sarvam.ai/text-to-speech`,
  header `api-subscription-key`, base64 wav in `audios[0]`. Keep the key in `.env`, never committed.
- Distinct voices per role (narrator vs character); diegetic phone lines get gentle EQ
  (`highpass=240,lowpass=3800`) at low level — heavy bandpass + echo reads as robot.
- **Pronunciation:** respell in the TTS input only, then round-trip verify — transcribe
  the wav and confirm it reads back as the intended word (`Jem-in-eye` → whisper hears "Gemini").
- **Loudness:** TTS arrives near 0 dBTP (clipping). Loudnorm at section mux:
  dialogue `loudnorm=I=-18:TP=-1.5:LRA=11`, quiet diegetic scenes ~9 LU under dialogue.

## 3. Beat times — word timestamps from the real audio

Whole-paragraph reads have no phrase-file boundaries, so the contract comes from ASR:

```bash
./transcribe.sh section.wav        # whisper-cli -ml 1 → words.json: [{text,start,end}]
```

Pick the cue words ("certified", "twelve", each list item) and key the GSAP timeline to
their starts plus the mux lead-in (`adelay=400` → +0.4). Numbers transcribe as digits
("240", not "two hundred and forty") — search accordingly.

Trigger a reveal ~0.05s BEFORE its phrase so the visual leads the voice fractionally. Landing after the words feels laggy.

## 4a. Generated art (illustrated scenes)

Hand-authoring representational SVG — rooms, people, props — was rejected wholesale
("every second of it is really bad"). Generate painted frames instead:

1. **Style block** prepended to every prompt (palette, light, composition rules,
   "No text, no captions, no lettering anywhere in the image", aspect).
2. **Character sheet first** — three views of the character on one sheet. Approve it,
   then pass it as a **reference image** to every frame containing that character, with
   "the same woman as the reference sheet". Pin details the sheet leaves ambiguous ("no glasses").
3. **Signature frame second** (the film's defining shot) — it becomes the style-lock
   reference for everything else.
4. Batch the rest, **one candidate per frame** (cost control), idempotent skip-if-exists.
5. **Contact-sheet ALL frames and read them.** Reject anything that dropped the payoff
   object or invented one; regenerate only those.
6. **Upscale ~1.4× (lanczos)** before camera moves so push-ins never soften.
7. Camera moves live in the composition: image in a `.cam` wrapper, slow
   scale/translate per shot, hard cuts between `clip` sections. 1.0→1.05 over 3–4s reads
   as cinema; anything faster reads as a slideshow transition.
8. UI/diagram scenes in the same film sit on a **generated backdrop** frame plus a dark
   shade div — flat hex backgrounds look pasted-on next to painted scenes.

Vertex path (when an AI-Studio key has no image quota — see troubleshooting):
`POST https://aiplatform.googleapis.com/v1/projects/$P/locations/global/publishers/google/models/gemini-3.1-flash-image:generateContent`
with gcloud bearer auth; parts = reference images then text; `"role":"user"` is required;
`generationConfig: {responseModalities:["IMAGE"], imageConfig:{aspectRatio:"16:9"}}`.

## 4b. Footage

**Crop first.** Screen recordings contain browser chrome, bookmarks, account names, other people's data:

```bash
ffmpeg -i rec.mov -vf "crop=W:H:X:Y" -frames:v 1 probe.png   # then LOOK at probe.png
```

Different recordings need different crops — a windowed capture has no chrome, a full-screen one does. Never reuse a crop across sources without checking.

**Ken Burns from stills, not video.** Extract a full-resolution still, then `zoompan`:

```bash
F=$(awk "BEGIN{printf \"%d\", $DUR*30}")
ffmpeg -y -loop 1 -i still.png -vf \
 "zoompan=z='$Z0+($Z1-$Z0)*on/$F':x='clip($CX-(iw/zoom)/2,0,iw-iw/zoom)':y='clip($CY-(ih/zoom)/2,0,ih-ih/zoom)':d=$F:s=1920x1080:fps=30,setsar=1" \
 -frames:v $F -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p -r 30 out.mp4
```

`CX,CY` is the point of interest in **source** pixels. Zooming a 3456px still to 1080p stays sharp; zooming the 1080p video does not.

## 5. Compositions

One per section, **silent**, full section length, footage windows left empty.

Required in every composition or lint fails:

```js
const tl = gsap.timeline();
window.__timelines = window.__timelines || {};
window.__timelines["main"] = tl;
```

Root element carries the contract:

```html
<div id="root" data-composition-id="main" data-start="0"
     data-width="1920" data-height="1080" data-duration="47">
```

Each beat is a `<section class="clip" data-start="..." data-duration="..." data-track-index="1">`; Hyperframes shows/hides by those attributes. Still add an explicit hard kill at the end of each beat so nothing bleeds:

```js
tl.to("#beat-wrap", { opacity: 0, duration: 0.4 }, 26.85);
tl.set("#beat-wrap", { opacity: 0 }, 27.3);   // hard kill on the boundary
```

Gates, in order — both must pass before rendering:

```bash
cd comp-s1 && npx hyperframes lint .    # directory, not a file
cd comp-s1 && npx hyperframes check .   # headless browser: runtime, layout, motion, contrast
```

`check` catches muted text below 3:1 contrast and elements overflowing the frame. Fix, don't ignore.

Render **one at a time**:

```bash
npx hyperframes render . -o "$OUT/s1.mp4" -f 30 -q high -w 2 --quiet
```

## 6. Sections

Per section, one ffmpeg command: card render + footage overlays + persistent logos + narration.

```bash
VOICE="aresample=48000,adelay=300,pan=stereo|c0=c0|c1=c0,apad"
ENC=(-c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p -r 30 \
     -c:a aac -b:a 192k -ar 48000 -ac 2 -movflags +faststart)

ffmpeg -y -i comp.mp4 -i shot.mp4 -i logo.png -i voice.wav -filter_complex "
[1:v]setpts=PTS+4.7/TB[f];
[0:v][f]overlay=0:0:enable='between(t,4.7,10.7)':eof_action=pass[b];
[2:v]scale=-1:54,format=rgba,colorchannelmixer=aa=0.85[lg];
[b][lg]overlay=54:46[v];
[3:a]$VOICE[au]" -map "[v]" -map "[au]" -t 47 "${ENC[@]}" sections/sec1.mp4
```

- `setpts=PTS+T/TB` shifts a clip to its window; `enable='between(t,a,b)'` gates it.
- `-t` pins the exact section length so concat math stays honest.
- Wrap in `if [ ! -f sections/secN.mp4 ]` so reruns skip finished work.
- A logo can be shown conditionally: `overlay=...:enable='not(between(t,0,10.4))'` — useful when one segment must carry different branding.

## 7. Final

Uniform encoding across sections makes concat lossless:

```bash
ffmpeg -f concat -safe 0 -i list_all.txt -c copy combined.mp4
```

Concat order is where sections get reordered — a new section can be inserted without touching any other file.

Music: sections carry **voice only**; the bed is muxed ONCE here so it flows across
cuts, and it ducks under speech automatically:

```bash
ffmpeg -y -i combined.mp4 -i bed.wav -filter_complex "
 [0:a]asplit=2[vox][key];
 [1:a]aresample=48000,pan=stereo|c0=c0|c1=c0,apad[mus];
 [mus][key]sidechaincompress=threshold=0.04:ratio=4:attack=60:release=700[duck];
 [duck][vox]amix=inputs=2:duration=first:normalize=0,
 alimiter=level_in=1:level_out=0.72:limit=0.71[a]" \
 -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k final.mp4
```

- **Never name a filter label `[v]`** — ffmpeg reads it as a stream specifier and the
  graph fails; and the voice must be `asplit` so it feeds both the duck key and the mix.
- No licensed track? **Synthesize the bed against the edit**: chord map keyed to scene
  offsets (pure-python additive pads → wav; then chorus + aecho + `loudnorm=I=-31:TP=-8`).
  Generated-to-fit means hits land on scene boundaries by construction and length always matches.
- A film with heavy silence still needs SOME bed — reviewers report bare silence as
  "no background music at all", i.e. a defect.

## 8. Verify

```bash
ffmpeg -v error -i final.mp4 -f null -          # must print nothing
```

Then extract a frame at **every** scene boundary, tile them, and Read the image:

```bash
for t in 3 14 24 36 44; do ffmpeg -y -ss $t -i final.mp4 -frames:v 1 f$t.png; done
ffmpeg -i f3.png -i f14.png ... -filter_complex "[0:v]scale=760:-1[a];...[a][b]hstack..." grid.png
```

Check on every frame: no browser chrome, no personal data, logos present and legible against that background, text not clipped, the reveal matches the words being spoken — and in cycled sequences, that each item is paired with ITS OWN outcome, not the previous one's (offset in/out timings silently mispair them).

Also verify loudness on the master: `loudnorm=print_format=json` → target ≈ −16 LUFS integrated, true peak ≤ −1.5 dBTP. Per-scene `volumedetect` means-in-windows proves every scene actually carries audio.

To measure whether an audio layer is actually present, subtract the voice-only mix from the final:

```bash
ffmpeg -i final.mp4 -i combined.mp4 -filter_complex \
 "[1:a]volume=-1[inv];[0:a][inv]amix=inputs=2:duration=first:normalize=0[b]" -map "[b]" bed_only.wav
ffmpeg -hide_banner -nostats -loglevel info -ss 190 -to 200 -i bed_only.wav -af volumedetect -f null - 2>&1 | grep mean_volume
```

A consistent level across windows proves the bed spans the whole edit.
