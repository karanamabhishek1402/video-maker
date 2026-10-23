---
description: Environment doctor for the video-studio pipeline — checks node, hyperframes CLI, ffmpeg, faster-whisper; prints exact fixes
---

Check the machine for every dependency of the video pipeline and print a
PASS/FIX table. Check, in order:

1. **node ≥ 20**: `node --version`. On WSL, also verify it's the Linux nvm
   build (`which node` must NOT be under `/mnt/c/`). If a Linux nvm node
   exists but isn't first in PATH, report the fix:
   `export PATH=$HOME/.nvm/versions/node/<ver>/bin:$PATH` (find `<ver>` via
   `ls ~/.nvm/versions/node/`).
2. **hyperframes CLI**: `npx hyperframes --version` (it auto-installs on
   first use; a version print is a PASS).
3. **ffmpeg + ffprobe**: `ffmpeg -version` and `ffprobe -version`.
4. **Python 3 + faster-whisper**: `python3 -c "import faster_whisper; print('ok')"`.
   If missing: `pip3 install --user faster-whisper`. Note: CPU inference is
   used everywhere (`device='cpu'`, `compute_type='int8'`) — no CUDA needed;
   a missing libcublas is NOT a problem.

Rules:

- Run only read-only checks yourself. Print install commands for anything
  missing; **never run sudo** — print any sudo line (e.g.
  `sudo apt-get install -y ffmpeg`) and tell the user to run it themselves by
  typing it with a `!` prefix in the prompt, then re-run `/video-setup`.
- Finish with a table: dependency | status (PASS / FIX) | fix command.
- When everything passes, say the environment is ready and point to
  `/video-new <project>` as the next step.
