---
name: mix-master
description: Use when muxing voiceover onto rendered scenes, assembling sections into the final video, generating or ducking the music bed, or mastering loudness — exact ffmpeg recipes for section mux (static gain to −18 LUFS), concat, sidechain ducking, and the −16.9 LUFS / −3.8 dBTP master chain.
---

# Mix & master

All audio levelling uses **measured static gain + limiter — never adaptive
loudnorm on VO clips**. Adaptive loudnorm pumps on gappy narration (it rides
the silences up); a bed's loudness is baked at generation time instead so no
loudnorm ever appears inside an `amix` graph.

## 1. Section mux (per section)

Measure the VO clip's integrated loudness:

```bash
ffmpeg -i secN/vo/p1.wav -af loudnorm=print_format=json -f null - 2>&1 | grep input_i
```

Static gain `G = -18 - input_i` (e.g. input_i −24.21 → G=6.21). Section
duration `D` = the comp's `data-duration`. Then:

```bash
ffmpeg -y -i secN/comp.mp4 -i secN/vo/p1.wav -filter_complex \
"[1:a]volume=${G}dB,alimiter=limit=0.7079:level=false,aresample=48000,\
adelay=300|300,pan=stereo|c0=c0|c1=c0,apad[au]" \
-map 0:v -map "[au]" -t $D -c:v copy -c:a aac -b:a 192k -ar 48000 -ac 2 \
-movflags +faststart secN/secN.mp4
```

- `adelay=300|300` is the 0.3 s mux lead — the same 0.3 s added to word
  starts when placing comp beats (`vo-pipeline`). Change one, change both.
- `alimiter=limit=0.7079` (−3 dBFS) catches peaks the static gain can create;
  the first Pathfinder mux without it clipped at +0.83 dBTP.

## 2. Assemble

```bash
printf "file 'sec1/sec1.mp4'\nfile 'sec2/sec2.mp4'\n..." > list.txt
ffmpeg -y -f concat -safe 0 -i list.txt -c copy joined.mp4
ffprobe -v error -show_entries format=duration -of csv=p=0 joined.mp4   # → DUR
python3 gen_bed.py $DUR        # regenerate bed at EXACT duration, −31 LUFS baked
```

Never reuse a bed from a previous duration — regenerate; it's seconds of CPU
and the fade-out lands correctly.

## 3. Master (bed duck + final chain)

```bash
ffmpeg -y -i joined.mp4 -i bed.wav -filter_complex \
"[0:a]asplit=2[vox][key];\
[1:a]aresample=48000,pan=stereo|c0=c0|c1=c0,apad[mus];\
[mus][key]sidechaincompress=threshold=0.04:ratio=4:attack=60:release=700[duck];\
[duck][vox]amix=inputs=2:duration=first:normalize=0,\
alimiter=level_in=1:level_out=0.89:limit=0.71,volume=-3.5dB[aout]" \
-map 0:v -map "[aout]" -c:v copy -c:a aac -b:a 192k -movflags +faststart final.mp4
```

- Sidechain: bed ducks under the voice (threshold .04, ratio 4, attack 60 ms,
  release 700 ms — musical, no pumping at these settings).
- `normalize=0` on amix is mandatory — without it amix halves both inputs.
- Target: **≈ −16.9 LUFS integrated / −3.8 dBTP**. Verify:

```bash
ffmpeg -i final.mp4 -af loudnorm=print_format=json -f null - 2>&1 | grep -E 'input_i|input_tp'
```

If it lands outside −16 to −18 LUFS, adjust the final `volume=` — do not
touch the limiter values.

## 4. Music bed

`references/gen_bed_template.py <duration> [out.wav]` — plucked arpeggios
(I-V-vi-IV @ 60 bpm) over a soft pad, no percussion, lowpassed at 3.6 kHz,
−31 LUFS/−8 TP baked in, 1.5 s ramp-in, 3 s fade-out, mono 48 kHz. Copied
into each project as `gen_bed.py` by `/video-new`.
