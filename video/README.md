# Vertex Buddy launch films

| Film | File | Size | Length | Status |
|---|---|---|---|---|
| **Launch film, version 5: "In the loop"** | `renders/vertex-buddy-launch-v5-1920x1080.mp4` | 1920 × 1080, 30 fps | 55.0 s | Newest. Made 2026-11-22 with free creative direction, on top of version 4. The loop in the tagline is the design: a neon ring that closes round real work, multiplies into five orbiting sessions, breaks when one turns pink (the camera dives into it), and closes again round Vertex. Five state close-ups inside gradient rings, a carousel of the four characters, typed text, stock footage, gradients throughout. Builder `source/build/launch5.mjs`, narration `scripts/voiceover-launch5.json`. Voice and music are placeholders. Frames were looked at; it was not watched or listened to. |
| Launch film, version 4 | `renders/vertex-buddy-launch-v4-1920x1080.mp4` | 1920 × 1080, 30 fps | 60.5 s | Newest (second cut, 2026-11-22: five close-up shots of how Vertex acts for each session state, gradients in place of flat colour, a bigger and more dramatic sound, a longer end card; the first cut is kept as `renders/vertex-buddy-launch-v4-first-cut.mp4`). A different film: black, white and neon green, typed text, real stock footage of people at their computers (`assets/stock/README.md` has the source and licence), pictures set inside a sentence, drifting cards, three labelled panels, rows of cards, a mark that builds from dots. After a second reference (`docs/reference-skuve.md`). Builder `source/build/launch4.mjs`, narration `scripts/voiceover-launch4.json`. Voice and music are placeholders. Frames were looked at; it was not watched or listened to. |
| Launch film, version 3 | `renders/vertex-buddy-launch-v3-1920x1080.mp4` | 1920 × 1080, 30 fps | 51.0 s | Newest. Made 2026-11-21 from version 2 for more energy and detail: cut faster (17 shots), every cut punches in, flashes and shakes on the big moments, bursts and rings, a drag-and-drop shot, a counting numeral, small detail labels, 40 sound cues and a beat in the placeholder music. Builder `source/build/launch3.mjs` (its additions are in the `FX` block), narration `scripts/voiceover-launch3.json`. Voice and music are placeholders. Frames were looked at; it was not watched or listened to. |
| Launch film, version 2 | `renders/vertex-buddy-launch-v2-1920x1080.mp4` | 1920 × 1080, 30 fps | 56.0 s | Newest. Made 2026-11-21 after studying a reference film (`docs/reference-lovio.md`): a flowing narration, type that picks out key words, sixteen shots each with its own look, 36 sound cues. Builder `source/build/launch2.mjs`, narration `scripts/voiceover-launch2.json`, timeline `storyboard/timeline-launch2.json`. Voice and music are placeholders. Frames were looked at; it was not watched or listened to. |
| Launch film, 55 s | `renders/vertex-buddy-launch-55s-1920x1080.mp4` | 1920 × 1080, 30 fps | 55.0 s | Kept. Made 2026-11-21 from the creative brief of that day: problem first, voiceover, music, six scenes. The voice and the music are placeholders. |
| First cut, 45 s | `renders/vertex-buddy-launch-1920x1080.mp4` | 1920 × 1080, 30 fps | 45.6 s | Kept. README lines only, no voice, no music. Its script is `SCRIPT.md`. |

## The 55-second film

| Time | Scene | Words on screen (also spoken) | What happens |
|---|---|---|---|
| 0:00 | The problem | CLAUDE IS WORKING. / YOU'RE DOING SOMETHING ELSE. / AND THEN... / IT NEEDS YOU. | Dark desktop, three sessions typing. Another app slides over them. One session stops and turns pink behind it; the frame freezes and pushes in on it. |
| 0:09 | Meet Vertex | MEET VERTEX BUDDY. / YOUR LITTLE COMPANION FOR CLAUDE CODE. | Cozy Vertex drops in, lands, looks around and waves. Windows arrive behind it. |
| 0:17 | The colours | EVERY APP. EVERY SPACE. EVEN FULL-SCREEN. / GREEN. WORKING. / YELLOW. FINISHED. YOUR TURN. / PINK. NEEDS YOUR ANSWER. | The window behind changes app, then goes full screen. Vertex works, celebrates, asks. The real speech bubble pops for yellow and pink. A row of five lights shows all five colours. |
| 0:29 | The product | SEE EVERY LIVE SESSION. / KNOW WHICH ONE NEEDS YOU. / CLICK. JUMP TO THE SESSION. | The cursor rests on Vertex and the bubble opens. A ring marks the outlined session. A click on Vertex brings that session's window forward. |
| 0:39 | The cast | FOUR CHARACTERS. / NINE BEHAVIOURS. / TWELVE FACES. | The four characters; nine behaviour clips cut on the beat with their names; twelve face close-ups. |
| 0:47 | The close | NO HOOKS. / NO CLAUDE SETTINGS CHANGES. / NOTHING SENT ANYWHERE. / CLAUDE DOES THE WORK. VERTEX KEEPS YOU IN THE LOOP. / VERTEX BUDDY | Vertex moves left; the line, the name, the address and "An independent project. Not made by Anthropic." land beside it. |

### Where it departs from the brief
- **No screen recordings.** The brief asks for recordings of the app over real windows. Claude Code cannot record this Mac's screen, so Vertex and its speech bubble are exported from the app itself, and the windows around them are plain drawings. To use real recordings, record them and they can be cut in.
- **The brief arrived cut off** in scene 6 ("Place Cozy Vertex beside"). The end card puts Vertex beside the name, the tagline and the address.
- **The voice is a local synthetic voice** (Kokoro, "Heart") and **the music is written in code**. Both are placeholders so the timing can be judged.
- **Scene 5 starts on time but ends at 0:47, not 0:48,** to give the last scene room for its narration.
- **"Rotating character stage"** is a row, not a turntable: the characters are flat footage. Rotating and splitting type were not used; text arrives by masks, cascades and cuts with blur.
- **One line was added:** "An independent project. Not made by Anthropic." on the end card.
- "Nothing sent anywhere" was checked against the app's code: it has no network code.

### Replace the placeholders
- **Voice:** record the 17 lines in `scripts/voiceover-launch.json` and save them over the files in `assets/audio/voice/launch/` with the same names. If a recording is longer than its slot the build stops and says which one.
- **Music:** put the track at `assets/audio/music/launch.mp3`. The film is cut at 120 BPM.
- Then: `video/source/bin/make build` and `video/source/bin/make render`.

## The first cut (45 s)


| Time | Scene | What happens | Words on screen |
|---|---|---|---|
| 0:00 | The day | One continuous shot. Cozy Vertex sleeps, wakes when a session opens, works, celebrates a finished session, asks for an answer, and is clicked. The light behind it follows the five status colours. | The README's first sentence, the four status meanings, "every Space, full-screen apps too", "Click the buddy: jumps to the waiting session" |
| 0:26 | The cast | All four characters side by side, changing behaviour together. | "Vertex comes as four characters." and "They all do every behaviour and pull every face; only the body differs." |
| 0:35 | The close | What Vertex touches, why it exists, then the name and the repository address. | "It needs no hooks…", "telling you is the whole point.", "Vertex Buddy" |

## What is real and what is drawn

- **Vertex is the app.** Every frame of the character was drawn by the app's own model and behaviour engine, exported with `ClaudeBuddy --film`. Nothing was redrawn or generated.
- **The speech bubble is the app's.** It is the real bubble view with three made-up sessions named `website`, `api` and `docs`.
- **The words are the README's.** The builder stops if a sentence on screen is not in the repository `README.md` word for word. The only text not from the README is the repository address.
- **The windows behind Vertex are drawings.** They are plain shapes standing in for "an app", not any real product's interface.
- **The z's are redrawn.** The app draws its floating extras in a separate layer that the export does not include. Only the sleeping z's were redrawn for the film; the working dots and thought bubbles are left out.

## Run it again

Every step takes an optional film name: `launch5` (version 5, the default), `launch4` (version 4), `launch3` (version 3), `launch2` (version 2), `launch` (the 55 s film) or `film` (the first cut).

```bash
video/source/bin/make footage   # record Vertex from the app and encode it (about 1 minute)
video/source/bin/make voice     # generate the placeholder narration (launch film)
video/source/bin/make build     # write the HyperFrames project
video/source/bin/make music     # write the placeholder music bed (launch film; run build first, then build again)
video/source/bin/make check     # run the checker
video/source/bin/make render    # render and master (about 1 minute)
video/source/bin/make frames 7.4,36.3   # single frames to look at, into docs/frames/
```

`footage` needs the app built first: `swift build -c release` in the repository root.

For the first cut: **to add music** put the track at `assets/audio/music/vertex.mp3` (or `.wav`), then build and render. The film is timed in beats at 100 BPM (`BPM` at the top of `source/build/film.mjs`); change that number to the track's tempo and every cut moves with it. With a track present the film is mastered to −15 LUFS; without one the sound effects are kept soft (about −23 LUFS).

**To change what Vertex does:** edit `source/footage-launch.json` (or `source/footage.json` for the first cut) (which behaviour starts when, which character, how large), then run `footage`, `build`, `render`.

**To change the words or layout:** edit `source/build/launch.mjs` (or `film.mjs`). What the two share is in `kit.mjs`. Files under `source/launch/` and `source/film/` are generated; do not edit them.

## What is where

| Folder | Holds |
|---|---|
| `assets/footage/` | The recorded takes: PNG frames, the transparent `.webm` made from them, each take's `take.json`, and the two bubble images |
| `assets/audio/sfx/` | Sound effects from the bundle that ships with HyperFrames, with their credits file |
| `assets/fonts/` | JetBrains Mono (SIL Open Font License, `OFL.txt` beside it). Inter comes bundled with HyperFrames. |
| `source/` | `footage.json`, the builder, the generated project `film/`, the tool scripts in `bin/`, the pinned tools |
| `storyboard/timeline-film.json` | Scene times, sound cues and every README line used, written by the builder |
| `renders/` | The finished film and its measured specification |
| `docs/frames/` | Frames looked at during review |
| `.home/` | The tools' private home folder (browser, caches). Rebuildable, ignored by git |

## What was checked

| Check | 55 s film | First cut |
|---|---|---|
| HyperFrames checker | Passes, no errors. Nine notes about clip timing inside the cast scene, which is intended. | Passes, no errors. |
| Frames of the finished file | Twelve frames taken from the rendered MP4 and looked at, one or more per scene. 44 layout frames were looked at during the build. | Twelve frames, plus 30 during the build. |
| Sound | Level −15.1 LUFS, peak −1.5 dBFS. Stretches with voice measure 3 to 6 dB above the music-only stretches beside them, and the bed drops further under each line. | Ten effects, each within 0.1 s of its picture. −23.3 LUFS. |
| Not checked | Neither film was watched or listened to: only still frames and measurements. Judge the cuts, the voice and the music by eye and ear before publishing. The motion skill's seam verifier was not run. | |

## Tools

HyperFrames 0.9.59, ffmpeg and the headless browser are the same pinned versions used for the FORMA films, kept inside this folder. Reporting and update checks are off, and nothing is signed in (`source/bin/env.sh`). The HyperFrames skills are not in this repository; install them into a project with `~/ClaudeAI/video-skills-kit/install.sh`.
