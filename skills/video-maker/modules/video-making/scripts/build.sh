#!/bin/bash
# Sections + final. Idempotent: delete one sections/secN.mp4 to rebuild just that one.
set -e
V=/path/to/work
NAR=/path/to/project/narration
LOGO=/path/to/logos
OUT=/path/to/project/final-video.mp4
mkdir -p "$V/sections"

ENC=(-c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p -r 30
     -c:a aac -b:a 192k -ar 48000 -ac 2 -movflags +faststart)
VOICE="aresample=48000,adelay=300,pan=stereo|c0=c0|c1=c0,apad"   # 0.30s lead-in, mono→stereo

# --- S1: cards only ---
if [ ! -f "$V/sections/sec1.mp4" ]; then
ffmpeg -y -v error -i "$V/renders/s1.mp4" -i "$LOGO/mark.png" -i "$NAR/s1-intro.wav" -filter_complex "
[1:v]scale=-1:54,format=rgba,colorchannelmixer=aa=0.85[lg];
[0:v][lg]overlay=54:46[v];
[2:a]$VOICE[au]" -map "[v]" -map "[au]" -t 43.5 "${ENC[@]}" "$V/sections/sec1.mp4"
echo "built sec1"; else echo "skip sec1"; fi

# --- S2: cards with a footage window at 4.7–10.7 ---
if [ ! -f "$V/sections/sec2.mp4" ]; then
ffmpeg -y -v error -i "$V/renders/s2.mp4" -i "$V/footage/shot.mp4" -i "$LOGO/mark.png" -i "$NAR/s2-body.wav" -filter_complex "
[1:v]setpts=PTS+4.7/TB[f1];
[0:v][f1]overlay=0:0:enable='between(t,4.7,10.7)':eof_action=pass[b];
[2:v]scale=-1:54,format=rgba,colorchannelmixer=aa=0.85[lg];
[b][lg]overlay=54:46[v];
[3:a]$VOICE[au]" -map "[v]" -map "[au]" -t 59 "${ENC[@]}" "$V/sections/sec2.mp4"
echo "built sec2"; else echo "skip sec2"; fi

# --- concat (order here is where sections get reordered/inserted) ---
cd "$V"
: > list_all.txt
for n in 1 2; do echo "file 'sections/sec$n.mp4'" >> list_all.txt; done
ffmpeg -y -v error -f concat -safe 0 -i list_all.txt -c copy combined.mp4
TOTAL=$(ffprobe -v error -show_entries format=duration -of csv=p=0 combined.mp4)

# --- music bed: MUST be longer than the video (see troubleshooting.md) ---
BED="$V/bed_long.mp3"
[ -f "$BED" ] || ffmpeg -y -v error -i "$V/track.mp3" -i "$V/track.mp3" \
  -filter_complex "[0:a][1:a]acrossfade=d=4:c1=tri:c2=tri[a]" -map "[a]" -c:a libmp3lame -q:a 2 "$BED"

FADEOUT=$(awk "BEGIN{printf \"%.2f\", $TOTAL-7}")
ffmpeg -y -v error -i combined.mp4 -i "$BED" -filter_complex \
"[1:a]aresample=48000,pan=stereo|c0=c0|c1=c1,volume=0.075,afade=t=in:st=0:d=1.5,afade=t=out:st=$FADEOUT:d=7[bed];
 [0:a][bed]amix=inputs=2:duration=first:dropout_transition=0:normalize=0[a]" \
 -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -ar 48000 -ac 2 -movflags +faststart "$OUT"

echo -n "final: "; ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
ffmpeg -v error -i "$OUT" -f null - && echo "DECODE_CLEAN"
