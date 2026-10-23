# video-maker skill

One Claude Code skill that bundles 18 video skills (HyperFrames, Media Use, Brag, Video Studio, Video Making). Use it to make Instagram Reels, promos, explainers, captions, voiceovers, music videos, slideshows and more.

## Install (one line)

macOS / Linux / WSL:
```bash
curl -fsSL https://raw.githubusercontent.com/karanamabhishek1402/video-maker/main/install.sh | sh
```

Windows PowerShell:
```powershell
irm https://raw.githubusercontent.com/karanamabhishek1402/video-maker/main/install.ps1 | iex
```

Then restart Claude Code and type `/video-maker` (or just ask, e.g. "make a 30-second Instagram reel about ...").

Requires Node.js 22+ and ffmpeg. Run `npx hyperframes doctor` to check.

## Credits

- [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes): Apache-2.0
- [latent-spaces/brag](https://github.com/latent-spaces/brag): MIT
- [ChanduKaranam/Video-studio](https://github.com/ChanduKaranam/Video-studio)
