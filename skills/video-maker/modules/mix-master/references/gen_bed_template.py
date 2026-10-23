#!/usr/bin/env python3
"""Music bed generator: gen_bed_template.py <duration_seconds> [out.wav]

Light plucked arpeggios over a soft pad, −31 LUFS baked in, mono 48 kHz.
Regenerate at the EXACT final video duration on every assembly — never
stretch or loop an old bed.

Why plucks: a held pad is a drone no matter what key it is in. What reads as
upbeat is *movement* — short struck notes with attack and decay. The pad sits
underneath at low level purely as glue. No percussion, so it never fights VO.
"""
import numpy as np, subprocess, wave, sys, os

SR = 48000
DUR = float(sys.argv[1]) if len(sys.argv) > 1 else 101.6
OUT = sys.argv[2] if len(sys.argv) > 2 else "bed.wav"
BPM = 60
BEAT = 60.0 / BPM
CHORD_BEATS = 8                # two bars per chord
FADE_OUT = 3.0

# I-V-vi-IV in C, the standard bright pop cycle. Voiced around C4-C5 so it sits
# above the narration's fundamentals instead of crowding them.
PROGRESSION = [
    ("C",  [261.63, 329.63, 392.00]),
    ("G",  [246.94, 293.66, 392.00]),
    ("Am", [220.00, 261.63, 329.63]),
    ("F",  [174.61, 220.00, 261.63]),
]

# walk up the chord and part-way back, with the octave on top
ARP =    [0,   1,    2,    3,    2,    1,    2,    1]
ACCENT = [1.0, 0.72, 0.80, 0.86, 0.74, 0.68, 0.78, 0.64]


def pluck(freq, n_total, start, decay=1.5):
    """One struck note: fast attack, exponential decay, a few harmonics."""
    n = min(int(SR * decay * 3.2), n_total - start)
    if n <= 0:
        return None
    t = np.arange(n) / SR
    env = np.exp(-t / decay)
    atk = min(int(SR * 0.025), n)
    env[:atk] *= np.linspace(0, 1, atk)
    out = np.zeros(n)
    # higher harmonics decay faster, which is what makes it read as struck
    for k, amp, d in ((1, 1.0, 1.0), (2, 0.20, 0.70), (3, 0.05, 0.50)):
        out += amp * np.sin(2 * np.pi * freq * k * t) * np.exp(-t / (decay * d))
    return out * env / 1.61


def main():
    n = int(SR * DUR)
    t = np.arange(n) / SR
    plucks, bass, pad = np.zeros(n), np.zeros(n), np.zeros(n)

    chord_len = CHORD_BEATS * BEAT
    n_chords = int(np.ceil(DUR / chord_len))

    for c in range(n_chords):
        # resolve home on the last chord instead of stopping mid-cycle
        _, notes = PROGRESSION[0] if c == n_chords - 1 else PROGRESSION[c % len(PROGRESSION)]
        c0 = c * chord_len
        tones = notes + [notes[0] * 2]

        for b in range(CHORD_BEATS):
            start = int(SR * (c0 + b * BEAT))
            if start >= n:
                break
            seg = pluck(tones[ARP[b]], n, start)
            if seg is not None:
                plucks[start:start + len(seg)] += seg * ACCENT[b]

        # one soft root per chord for grounding — struck, not held
        seg = pluck(notes[0] / 2, n, int(SR * c0), decay=2.2)
        if seg is not None:
            s = int(SR * c0)
            bass[s:s + len(seg)] += seg * 0.5

        a0, a1 = int(SR * c0), min(int(SR * (c0 + chord_len + 0.9)), n)
        env = np.zeros(n)
        env[a0:a1] = 1.0
        f = int(SR * 0.9)
        if a0 > 0:
            m = min(f, n - a0)
            env[a0:a0 + m] = np.linspace(0, 1, f)[:m]
        if a1 - f > a0:
            env[a1 - f:a1] = np.linspace(1, 0, f)
        for fq in notes:
            pad += np.sin(2 * np.pi * fq * t) * env / len(notes)

    mix = plucks + 0.34 * bass + 0.20 * pad
    mix /= max(1e-9, np.abs(mix).max())
    mix *= 0.6

    ramp = int(SR * 1.5)
    mix[:ramp] *= np.linspace(0, 1, ramp)
    out = int(SR * FADE_OUT)
    mix[-out:] *= np.linspace(1, 0, out)

    raw = OUT + ".raw.wav"
    with wave.open(raw, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((mix * 32767).astype("<i2").tobytes())

    # bake loudness here — keep loudnorm out of any later amix graph
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", raw,
                    "-af", "lowpass=f=3600,loudnorm=I=-31:TP=-8:LRA=8,aresample=48000",
                    "-ar", "48000", "-ac", "1", OUT], check=True)
    os.remove(raw)
    print(f"{OUT} · {DUR:.1f}s · {BPM}bpm · {n_chords} chords · "
          f"{n_chords * CHORD_BEATS} plucked notes")


if __name__ == "__main__":
    main()
