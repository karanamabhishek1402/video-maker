#!/usr/bin/env python3
"""Word timestamps for VO retiming: whisper_words.py <in.wav> <out.json>
CPU only (int8) — works without libcublas/CUDA. Mis-transcribed words are
fine; only the TIMINGS are used to place visual beats."""
import sys, json
from faster_whisper import WhisperModel

wav, out = sys.argv[1], sys.argv[2]
model = WhisperModel("base.en", device="cpu", compute_type="int8")
segments, _ = model.transcribe(wav, word_timestamps=True)
words = [{"word": w.word.strip(), "start": round(w.start, 3), "end": round(w.end, 3)}
         for s in segments for w in s.words]
json.dump(words, open(out, "w"), indent=1)
print(f"{len(words)} words -> {out}")
