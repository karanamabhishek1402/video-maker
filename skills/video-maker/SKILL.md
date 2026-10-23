---
name: video-maker
description: All-in-one video skill — make, edit, animate, caption, voice, score and render any video with HyperFrames (HTML rendered to MP4). Covers Instagram Reels / Shorts / TikTok (9:16), product launch and promo videos, explainers, narrated demos, talking-head captions and overlays, music and beat-synced videos, charts, maps, kinetic type, logo stings, slideshows/decks, website or GitHub-PR-to-video, Figma-to-video, Remotion ports, voiceover (TTS), music beds, SFX, transcription, mixing and mastering. Use for any request to create or change a video, animation, motion graphic, reel, promo, voiceover or render, or when the user says /brag, /video-new, /video-setup or /video-ship.
---

# Video Maker

One skill that bundles 18 video skills. Each one lives intact under `modules/<name>/` with its own `SKILL.md`, references and scripts.

`<skill-dir>` is the folder that contains this file (Claude Code prints it as "Base directory for this skill"). Every path below is relative to it.

## How to use the modules

1. Pick the module from the routing table below and **read its `SKILL.md` in full** before working.
2. Inside a module, relative paths (`references/x.md`, `scripts/y.mjs`, `../hyperframes/...`) resolve from that module's own folder.
3. Modules mention each other as skills, e.g. "`/media-use`", "load the `hyperframes-cli` skill", "`/hyperframes:hyperframes`", or `${CLAUDE_PLUGIN_ROOT}/skills/<name>/`. These are **not** separately installed. Always resolve them inside this bundle: read `<skill-dir>/modules/<name>/SKILL.md` (or the named file under `<skill-dir>/modules/<name>/`). Never run `npx skills add` or `npx hyperframes skills update` to fetch them.
4. Retired HyperFrames skill names some modules still mention now live inside `modules/hyperframes/`:

   | Old name | Read instead |
   | --- | --- |
   | `hyperframes-core` | `modules/hyperframes/SKILL.md` (Contract) + `references/format.md` |
   | `hyperframes-animation`, `hyperframes-keyframes` | `modules/hyperframes/references/motion.md`, `references/runtimes.md` |
   | `hyperframes-creative` | `modules/hyperframes/references/look.md`, `story.md`, `sound.md` |
   | `hyperframes-audio` | `modules/hyperframes/references/sound.md`, then `modules/media-use` |
   | `hyperframes-studio` | `modules/hyperframes/SKILL.md` (desktop app + work loop) |
   | `general-video`, `product-launch-video`, `faceless-explainer`, `music-to-video`, `motion-graphics`, `pr-to-video` | `modules/hyperframes/SKILL.md` → its "What to read" table |
   | `embedded-captions`, `talking-head-recut` | `modules/hyperframes/references/captions.md`, `overlays.md` |

5. When running the HyperFrames CLI (`npx hyperframes ...`), set `HYPERFRAMES_SKIP_SKILLS=1` in the environment so it does not install duplicate standalone copies of these skills. The `modules/hyperframes/references/plugin-installation.md` rules do not apply: this bundle is a standalone skill.

## Routing

Start with **`modules/hyperframes/SKILL.md`** for almost any video. It holds the render contract and work loop and points to the right reference for each kind of video. Add the modules below as the task needs them.

| The request | Read |
| --- | --- |
| Any new video, edit, render; Reels / Shorts / vertical 9:16 | `modules/hyperframes/SKILL.md` → `references/types/vertical.md` |
| Launch, promo, explainer, music video, chart, map, 3D, character short | `modules/hyperframes/SKILL.md` → its "What to read" table |
| Captions, subtitles, cards over a talking head | `modules/hyperframes/references/captions.md`, `overlays.md` |
| Voiceover / TTS, music, SFX, images, logos, transcription, background removal, colour grade | `modules/media-use/SKILL.md` |
| CLI commands: init, preview, check, snapshot, render, cloud/Lambda render, doctor | `modules/hyperframes-cli/SKILL.md` |
| Named effect, transition, chart, terminal window, confetti, other ready-made blocks | `modules/hyperframes-registry/SKILL.md` |
| Presentation / pitch deck / interactive slides | `modules/slideshow/SKILL.md` |
| Figma link or design → video | `modules/figma/SKILL.md` |
| Porting a Remotion (React) project | `modules/remotion-to-hyperframes/SKILL.md` |
| "Make a launch video of this project", `/brag` | `modules/brag/SKILL.md` (falls back to `modules/brag-slim/SKILL.md`) |
| Narrated product/demo/story video with Kokoro or Sarvam TTS, Vertex/Gemini art, whisper timings, ffmpeg assembly | `modules/video-making/SKILL.md` |
| Studio-style project with workspace folders, versioned cuts, mastered audio | `modules/video-studio/SKILL.md` |
| `/video-new`, `/video-setup`, `/video-ship` | `modules/video-studio/commands/video-new.md`, `video-setup.md`, `video-ship.md` (follow as instructions) |
| Voiceover script, pronunciation, word timestamps, retiming to narration | `modules/vo-pipeline/SKILL.md` |
| Writing scene compositions, on-screen copy, lint gates | `modules/comp-craft/SKILL.md` |
| Muxing VO, music bed, ducking, loudness mastering | `modules/mix-master/SKILL.md` |
| Multi-scene motion that should feel like one camera move | `modules/motion-doctrine/SKILL.md` → `cut-the-curve`, `seam-craft`, `oversized-cursor` |

## Instagram Reels quick defaults

- Canvas 1080×1920, 30 fps, usually 15–60 s (Reels allows up to 3 min).
- Keep captions and key text inside the 80% title-safe box. Leave the bottom ~20% and the right edge clear for Instagram's caption, buttons and progress bar.
- Hook in the first 1–2 s. Burn in captions, because most viewers watch muted.
- Deliver H.264 MP4 with AAC audio.

## First run on a new machine

Needs Node.js 22+ and ffmpeg. Check with `npx hyperframes doctor` (or `/video-setup` for the Video Studio pipeline). Optional extras: Python for local TTS/music, Docker for containerised renders. Fix what `doctor` reports before building.

## Credits

Bundled from [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) (Apache-2.0), [latent-spaces/brag](https://github.com/latent-spaces/brag) (MIT), [ChanduKaranam/Video-studio](https://github.com/ChanduKaranam/Video-studio) and the `video-making` skill. Licences are in `LICENSES/`.
