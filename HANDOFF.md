# Vertex Buddy: where things stand (2026-11-22)

Use this file to pick the work up later or on another computer.

## The app

Vertex Buddy 2.0 is on this branch (`vertex-buddy-v2`): four characters, nine behaviours, the live session list. `main` still holds version 1. See [README.md](README.md).

Added since the 2.0 commit: `--film`, which exports Vertex as transparent frame sequences for videos (`Sources/ClaudeBuddy/Film.swift`). The running app's behaviour is unchanged.

## The launch films

Everything is in [video/](video/README.md). Six cuts have been made. The rendered MP4s are **not** in git (they are generated); rebuild them with the commands in `video/README.md`.

| Film | Builder | State |
|---|---|---|
| First cut, 45 s | `video/source/build/film.mjs` | README lines only, no voice |
| 55 s | `launch.mjs` | From the creative brief: problem first, voice, music |
| Version 2 | `launch2.mjs` | Narrated, sixteen shots, after the Lovio reference |
| Version 3 | `launch3.mjs` | Version 2 cut faster, with impacts and bursts |
| Version 4 | `launch4.mjs` | A different film: black, white and neon, typed text, stock footage, gradients, state close-ups. **The one that was liked.** |
| Version 5, "In the loop" | `launch5.mjs` | Ring motif, orbits. **Not liked.** |

**Where it stopped:** an options board of four new looks was made for the next film: `video/docs/options/vertex-film-options.png` (A Desktop story, B Toy studio, C Pixel arcade, D One light). No choice has been made yet.

In every film the voice is a local synthetic placeholder and the music is written in code. No film has been watched or listened to by the assistant that built it: only still frames and sound measurements were checked.

## To rebuild on a fresh copy

1. Build the app: `swift build -c release`.
2. In `video/source`: `npm ci`, then `bin/hf browser ensure` (downloads the headless browser into `video/.home`).
3. The local voice and the music script need Python 3.10+ with `kokoro-onnx`, `soundfile`, `numpy` and `scipy` in `video/.home/venv` (see `video/README.md`, Tools).
4. Stock footage: download the clips listed in `video/assets/stock/README.md` and prepare them (the ffmpeg settings are described there).
5. `bin/make footage`, `bin/make voice`, `bin/make build`, `bin/make music`, `bin/make build`, `bin/make render`. Add a film name (`launch4`, for example) after any step.

## Not in this repository

- Rendered films (`video/renders/*.mp4`) and footage recorded from the app (`video/assets/footage*`).
- The stock clips themselves (third-party; sources and licence are in `video/assets/stock/README.md`).
- Tools and caches (`video/.home`, `video/source/node_modules`).
- The HyperFrames skills for Claude Code. A pinned copy is kept on the original Mac at `~/ClaudeAI/video-skills-kit/`; they come from `github.com/heygen-com/hyperframes` v0.9.59.
- The Claude conversation itself.
