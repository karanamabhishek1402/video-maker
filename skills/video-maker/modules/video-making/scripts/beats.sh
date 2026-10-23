#!/bin/bash
# Print the start time of every phrase inside its section — the numbers you paste
# into the GSAP timeline. Keep the sequences identical to tts-bank.sh.
BASE=/path/to/work/narration
dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$BASE/phrases/$1.wav"; }

section() {
  local name="$1"; shift
  echo "=== $name"
  local t=0
  for spec in "$@"; do
    IFS=':' read -r pid gap <<< "$spec"
    local d=$(dur "$pid")
    printf "  %-5s start=%6.2f dur=%5.2f end=%6.2f\n" "$pid" "$t" "$d" "$(awk "BEGIN{print $t+$d}")"
    t=$(awk "BEGIN{print $t+$d+(${gap:-0})}")
  done
  printf "  TOTAL %.2f\n" "$t"
}

# Add the audio lead-in (adelay, typically 0.30) to these when placing visuals,
# then fire each reveal ~0.05s early so the visual leads the voice.
section s1-intro q01:0.40 q02
