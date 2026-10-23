#!/bin/bash
# Phrase-bank generator. Idempotent: existing phrase wavs are skipped, so a
# killed session resumes, and changing one line means deleting one wav.
#
# Adapt: BASE/WBASE/DEST, the PHRASES list, and the assemble() calls.
set -e
BASE=/path/to/work/narration                       # WSL/native path for reads
WBASE='C:\path\to\work\narration'                  # native path for the TTS CLI (WSL only)
DEST=/path/to/project/narration
mkdir -p "$BASE/phrases" "$DEST"

# id|speed|text      speed 1.0 = emphatic, 1.05 = connective
# "..." = a beat, "—" = a turn. Phonetic respellings go here, not in on-screen copy.
PHRASES=(
"q01|1.0|Institutions everywhere are rolling out Gemini Enterprise."
"q02|1.05|Thousands of licenses... handed out in a single week."
)

for entry in "${PHRASES[@]}"; do
  IFS='|' read -r id speed text <<< "$entry"
  out="$BASE/phrases/$id.wav"
  if [ -f "$out" ]; then
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out" 2>/dev/null || echo 0)
    awk "BEGIN{exit !($dur > 0.3)}" && { echo "skip $id"; continue; }
  fi
  echo "tts $id (speed $speed)"
  npx hyperframes tts "$text" -o "$WBASE\\phrases\\$id.wav" -v af_sky --speed "$speed" --json \
    > "$BASE/phrases/$id.log" 2>&1
done

# Silences must match the TTS output format (Kokoro: 24 kHz mono)
for d in 0.25 0.30 0.35 0.40; do
  [ -f "$BASE/sil_$d.wav" ] || \
    ffmpeg -y -v error -f lavfi -t "$d" -i anullsrc=r=24000:cl=mono -c:a pcm_s16le "$BASE/sil_$d.wav"
done

# assemble <section-name> <id:gap-after> ... (last id has no gap)
assemble() {
  local name="$1"; shift
  local list="$BASE/list_$name.txt"; : > "$list"
  local n=$# i=0
  for spec in "$@"; do
    i=$((i+1)); IFS=':' read -r pid gap <<< "$spec"
    echo "file 'phrases/$pid.wav'" >> "$list"
    [ "$i" -lt "$n" ] && [ -n "$gap" ] && echo "file 'sil_$gap.wav'" >> "$list"
  done
  ( cd "$BASE" && ffmpeg -y -v error -f concat -safe 0 -i "$list" -c:a pcm_s16le "$DEST/$name.wav" )
  echo -n "$name: "; ffprobe -v error -show_entries format=duration -of csv=p=0 "$DEST/$name.wav"
}

assemble s1-intro q01:0.40 q02
