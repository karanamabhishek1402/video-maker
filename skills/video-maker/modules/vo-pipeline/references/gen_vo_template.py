#!/usr/bin/env python3
"""Voiceover generator — Kokoro af_sky @ 0.80, breath-group reads.

Battle-tested rules baked in:
- keep 80ms head / 150ms tail natural margins when trimming silence
- 0.1s reversed fade on the tail (never hard-gate the breath off)
- gaps in the SPEC are speech-to-speech; shrink each by the 0.23s kept margins
- 120ms head delay + 0.3s tail pad on the joined file
- static gain to -18 LUFS happens at section MUX time, never adaptive loudnorm here
- idempotent: skips secN/vo/pN.wav that already exist (this is what makes
  forking a cut cheap — copy the tree, delete only changed sections' wavs)

SPEC format: {"secN/vo/p1": [text, gap, text, gap, ..., text]}
- text items are breath groups: one spoken phrase the voice reads in one go
- float items are the pause AFTER the preceding group, in seconds
Pronunciation: rephrase, don't respell (see the vo-pipeline SKILL.md).
"""
import subprocess, os, glob

# Prefer the Linux nvm node on WSL if present (Windows node breaks npx here)
for node_bin in sorted(glob.glob(os.path.expanduser("~/.nvm/versions/node/*/bin")), reverse=True):
    os.environ["PATH"] = node_bin + ":" + os.environ["PATH"]
    break

MARGIN = 0.23  # 0.08 head + 0.15 tail kept on each group

SPEC = {
    # Example — replace with your script's breath groups:
    # "sec1/vo/p1": [
    #     "Your bill for AI has one line per model.", 0.5,
    #     "So — what's actually running in there?", 0.45,
    #     "Pathfinder answers that — from the traffic your systems have already generated.",
    # ],
}

def run(c): subprocess.run(c, shell=True, check=True)

for out, items in SPEC.items():
    if os.path.exists(out + ".wav"):
        print(out, "exists — skip"); continue
    os.makedirs(os.path.dirname(out), exist_ok=True)
    parts, gi = [], 0
    for it in items:
        if isinstance(it, float):
            gap = max(0.1, it - MARGIN)
            g = f"/tmp/gap{gi}.wav"; gi += 1
            run(f"ffmpeg -y -v error -f lavfi -i anullsrc=r=24000:cl=mono -t {gap} -c pcm_s16le {g}")
            parts.append(g); continue
        f = f"/tmp/grp{len(parts)}.wav"
        txt = it.replace("'", "'\\''")
        run(f"npx hyperframes tts '{txt}' -o {f}.raw.wav -v af_sky -s 0.80 >/dev/null 2>&1")
        # trim silence but KEEP natural margins; fade the tail instead of gating it
        run(f'ffmpeg -y -v error -i {f}.raw.wav -af "'
            f'silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08,'
            f'areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.15,'
            f'afade=t=in:d=0.1,areverse" {f}')
        parts.append(f)
    with open("/tmp/vlist.txt", "w") as fh:
        for p in parts: fh.write(f"file '{p}'\n")
    run(f"ffmpeg -y -v error -f concat -safe 0 -i /tmp/vlist.txt -af 'adelay=120|120,apad=pad_dur=0.3' {out}.wav")
    d = subprocess.check_output(f"ffprobe -v error -show_entries format=duration -of csv=p=0 {out}.wav", shell=True)
    print(out, round(float(d), 2), "s")
