# Vertex Buddy: launch video plan

> Status: **first cut of the 16:9 hero film is rendered (2026-11-21):** [video/renders/vertex-buddy-launch-1920x1080.mp4](video/renders/vertex-buddy-launch-1920x1080.mp4), 45.6 s. How it was made and what was checked: [video/README.md](video/README.md).
> It follows the recommendations below (B + C with the cast burst, README first sentence as the opening, Cozy Vertex leading, no voice). It has sound effects but no music yet. The vertical film, the teaser, the README loops and the stills are not made.
> Still open: music, where it launches, and the three launch items at the end of section 6.
>
> Copy source: [README.md](README.md). Vertex Buddy has no website, so the README is the only published messaging.
> Visual source: the app itself ([Sources/ClaudeBuddy](Sources/ClaudeBuddy)), which can draw any character in any pose off screen.

---

## 1. What we already have

### The content (used as is)
- **The promise, in the README's first sentence:** "Vertex is a little 3D buddy that floats above every app on your Mac (every Space, full-screen apps too) and tells you when a Claude Code session is waiting for you."
- **The colour code:** five glows, each with its meaning written out (asleep, sessions open, working, your turn, needs your answer).
- **The cast:** four named characters (Cloud, Pixel, Robo and Cozy Vertex), each with a one-line description.
- **The behaviours:** nine, each with a sentence of what Vertex does. Twelve named faces.
- **A ready-made story:** the "In Auto" paragraph is already a day in Vertex's life: no sessions means sleeping, quiet sessions mean idle, a busy session means working, and a waiting session "always comes first".
- **The trust line:** "It needs no hooks and no changes to Claude settings, and only reads the files, never writes them."
- **The closing thought:** "telling you is the whole point."

**What the README does not say.** It never states the problem (you look away while Claude works and miss that it has stopped). A film that opens on that problem would be adding a line the source does not have, so it needs your approval first (section 6).

### The visuals
- **The app is the camera.** Three pieces that already exist make film footage possible without screen recording:
  - `BehaviorEngine.simulate` plays any behaviour from a fixed seed, so the same take comes out every time;
  - `Robot3D.image` draws one frame of any of the four characters off screen at any size;
  - `--snapshot` already uses both to write the PNG sheets.
- **What that gives:** Vertex on a transparent background, any character, any behaviour, 30 frames a second, at film resolution, with its own lighting and floor shadow.
- **What it does not give:**
  - the floating extras (thought dots, z's, music notes, "?", firefly, alert glow) are separate layers in the live app and are not in an exported frame, so the film redraws them;
  - the speech bubble comes out only as a still image, so the film rebuilds it to animate it;
  - Claude Code cannot record the screen on this Mac, so there is no footage of Vertex over real apps unless you record it yourself.

### Video work already done on this Mac
| Project | Where | What it proves |
|---|---|---|
| FORMA films (four films, 16:9 and 9:16, 43 to 88 s) | `../FORMA/video/` | A complete working pipeline: HyperFrames 0.9.59, a frame-accurate recorder, a builder timed in beats, a checker, sound mastering, a local voice, a scratch music bed and sound effects. All installed inside that project only. |
| Pixels to Prompt launch film (scripts approved, recording test passed today) | `../untitled folder/pixels-to-prompt-practise-5/` | The same brief as this one, carried through two approval gates. It adds a line bank with a checker that fails any line not found word for word in the source, and a sketch of the future plugin. |

---

## 2. Skills and tools found

| Tool or skill | Where it stands | What it does | Fit for Vertex |
|---|---|---|---|
| **HyperFrames** (HeyGen, Apache-2.0) | Skills installed in this project and in FORMA. Also listed as a plugin in Claude's directory. | Turns HTML, CSS and GSAP animation into MP4. Has a checker, a frame grabber, a local voice, about 450 ready blocks, and written guides for launch, character, 3D, explainer and vertical films. | ★★★ Main engine. Free for a company, already proven here twice. |
| **Craft skills** from the HyperFrames repository: `motion-doctrine`, `cut-the-curve`, `seam-craft`, `oversized-cursor` | Installed in this project and in FORMA | Film grammar: how cuts, type entries and the big cursor should move | ★★★ The big cursor is exactly right for "click the buddy" |
| **FORMA recorder and Pixels to Prompt capture library** | Code in those projects | Record a web page frame by frame | ★ Not needed. Vertex is a Mac app, so the footage comes from the app's own renderer. |
| **Verbatim line checker** (`lines.py`) | Code in Pixels to Prompt | Fails a script that rewords the source | ★★★ Reuse the idea with the README as the source |
| **Remotion** official skills (`remotion-dev/skills`) and the Remotion plugin | Not installed | React-based video, the most widely used | ★★ Capable, but a second stack, and its licence is free only for teams of up to three. E2M would need a paid company licence. |
| `video-shotcraft` (Remotion shot recipes for product videos) | Listed in the directory | Ready shot recipes and sound effects | ★ Tied to Remotion |
| `anthropic-skills:remotion` | Available in this session | Walkthrough videos of Stitch projects only | Not a fit |
| **Higgsfield** connector, **Runway** plugin | Need sign-in; charged per generation | AI-generated footage from text or an image | ★ See concept F |
| **ElevenLabs** connector | Needs sign-in | Voiceover, music, sound effects | ★★ Only if you want a studio voice or a generated track |
| Local Kokoro voice, bundled sound effects, scratch music script | Working in FORMA | Free, on this Mac, nothing sent anywhere | ★★ For judging a cut |
| `watch-video` | Listed in the directory | Lets Claude study a reference video: key frames and transcript | ★★ Useful if you have a launch film you want this one to feel like |
| `anthropic-skills:slack-gif-creator` | Available in this session | Looping GIFs with size limits | ★★ For the README loops in section 4 |
| **design-master** agents | Installed, v0.2.1 | The gated workflow to copy for the plugin | The pattern, not a film tool |

**On this Mac:** Node 22.11 meets HyperFrames' requirement. ffmpeg is not installed; FORMA carries its own copy inside its project folder, and this project would do the same.

**Shared account:** every install would go inside this project only, with nothing signed in.

---

## 3. Six concepts from the same README

Each uses only the README's sentences. Adapting means choosing, ordering and timing them.

### A. Cinematic brand launch: "Meet Vertex"
- **What:** a character reveal. Dark studio, slow turns, the hood, the glossy screen, the eyes lighting up, then the other three characters stepping in. The README's own phrase is the look: "lit like a toy on a photo table".
- **Length:** 30 to 40 s, music-led, very few words.
- **Achieves:** the strongest first impression of the character.
- **Weakness:** says the least about what Vertex is for.

### B. Story-driven: "A day with Vertex"
- **What:** the "In Auto" paragraph played out in order. Vertex sleeps, wakes when a session opens, works while Claude works, hops yellow when it finishes, goes pink when it needs an answer, gets clicked, and goes back to sleep.
- **Length:** 45 to 60 s.
- **Achieves:** explains the whole product without explaining. The five glows become the colour script of the film.
- **Weakness:** needs a desktop to stand on, which has to be drawn for the film (see section 5).

### C. Motion graphics and kinetic type
- **What:** the README's lines as large type, with Vertex acting each one beside the words. The glow table becomes five fast colour beats.
- **Length:** 20 to 30 s, 9:16 first.
- **Achieves:** fastest to make, works with the sound off, most shareable.
- **Weakness:** on its own it is a feature list with a mascot.

### D. Product showcase
- **What:** the cast and the range. Four characters in the same pose, nine behaviours in quick succession, the twelve faces as a grid, then hover, click, drag and right-click.
- **Length:** 45 to 60 s.
- **Achieves:** proof of how much is in it.
- **Weakness:** no story, so it suits people who already care.

### E. Explainer
- **What:** how it works, in the README's order: what it is, what the colours mean, how it knows ("reads those files once a second"), how to use it, how to build it.
- **Length:** 60 to 90 s, narrated or captioned.
- **Achieves:** answers every question a developer would ask.
- **Weakness:** the least emotional, and the longest.

### F. AI-generated visual storytelling
- **What:** generated footage of a robot buddy on a desk or in a room.
- **Why it does not fit:**
  1. a generated character will not match the real model from shot to shot;
  2. it would show a product that is not the one people download;
  3. the real one can already be filmed exactly, for free;
  4. it needs a sign-in and credits.
- **Where it could help:** an abstract background plate at most, and only if you ask for it.

### Comparison
| | A Cinematic | B Story | C Kinetic | D Showcase | E Explainer | F AI-generated |
|---|---|---|---|---|---|---|
| Launch feel | ●●●●● | ●●●● | ●●● | ●●● | ●● | ●●●● |
| Says what it is for | ●● | ●●●●● | ●●●● | ●●● | ●●●●● | ● |
| Shows the real product | ●●●●● | ●●●●● | ●●●● | ●●●●● | ●●●●● | ● |
| Works with sound off | ●●● | ●●●● | ●●●●● | ●●●● | ●● | ●●● |
| Effort | Medium | Medium-high | Low | Medium | Medium | Medium, plus credits |
| Reusable in the plugin | High | High | Very high | High | High | Low |

---

## 4. Recommendation: B + C, with a burst of D

**"A day with Vertex", told in kinetic type.** The Auto paragraph is the story (B). The README's sentences land as large type while Vertex acts them (C). One fast burst in the middle shows the four characters, the behaviours and the faces (D). The last shot borrows A's studio lighting for the end card.

### Why this mix
- It keeps the messaging as written: the type is the README, word for word.
- The story already exists in the source, so nothing is invented.
- The five status colours give the film its structure for free.
- Everything on screen is the real model drawn by the real app.
- It reads with the sound off, which is how LinkedIn, X and a GitHub page play video.
- It cuts down cleanly: the colour beats alone are the 15 s teaser.

### Deliverables
| Version | Size | Length | Use |
|---|---|---|---|
| Hero film | 1920 × 1080, 30 fps | about 45 s | GitHub README, LinkedIn, YouTube |
| Vertical film | 1080 × 1920, composed separately | about 30 s | LinkedIn mobile, Reels, Shorts |
| Teaser | 1080 × 1350 and 1080 × 1920 | 15 s | Pre-launch post |
| README loops | small GIFs, 4 to 6 s each | — | One per character or behaviour, in the README itself |
| Stills | 1280 × 640 and 1080 × 1350 | — | GitHub social preview, post image |

### Draft beat sheet for the 45 s hero
Every line is from the README. This is a draft for Gate 2, not a script.

| Time | Glow | Picture | Words on screen |
|---|---|---|---|
| 0–5 s | Lavender | A quiet drawn desktop. Cozy Vertex sits asleep in the corner, z's drifting up. | Vertex is a little 3D buddy that floats above every app on your Mac |
| 5–9 s | Aqua | A session opens. Vertex wakes, stretches, looks around. | Sessions open, nothing to do |
| 9–15 s | Green | Vertex leans in and types. The window behind changes to another app and Vertex stays on top. | Claude is working → every Space, full-screen apps too |
| 15–21 s | Yellow | It hops, a chime, the speech bubble pops. | A session finished: your turn |
| 21–26 s | Pink | Wide eyes. The big cursor clicks Vertex and the view jumps to the session. | A session needs your answer → Click the buddy: jumps to the waiting session |
| 26–34 s | All | The burst: four characters in one pose, nine behaviours on the beat, the twelve faces as a grid. | Vertex comes as four characters. → They all do every behaviour and pull every face; only the body differs. |
| 34–39 s | Aqua | Vertex stands calm, glancing at the files it reads. | It needs no hooks and no changes to Claude settings, and only reads the files, never writes them. |
| 39–45 s | Green, then lavender | Studio light. Vertex waves, then sits down to sleep. End card: name and repository address. | telling you is the whole point. |

**Sound:** music-led, cut on the beat as FORMA does. Sound effects carry the moments: the chime, the hop, the bubble pop, the click.

**Voice:** none recommended. The README is product copy, not a personal story, and the type already carries every line.

---

## 5. How it would be made

Modelled on design-master's gated pipeline. Approvals are marked ✔.

| # | Step | What happens | Gate |
|---|---|---|---|
| 1 | Intake | A short brief: goal, platforms, lengths, voice, music source | — |
| 2 | Line bank | Every usable README sentence, tagged by section, with a checker that fails rewording | — |
| 3 | Concept | This document | ✔ **1: concept** |
| 4 | Script and beat sheet | Lines chosen and timed; the checker confirms each is word for word | ✔ **2: script** |
| 5 | Styleframes and animatic | One real frame per beat from the app, on a storyboard page, plus a silent timed cut | ✔ **3: the look** |
| 6 | Footage | A new export mode in the app writes Vertex as transparent frame sequences: character, behaviour, seed, length | — |
| 7 | Audio | Chosen music, sound effects, voice only if wanted | — |
| 8 | Build | HyperFrames compositions timed in beats; 16:9 and 9:16 composed separately from one shared kit | — |
| 9 | Check | HyperFrames checker, frame-by-frame review, loudness, the verbatim check, the honesty rules below | — |
| 10 | Review | You watch the films | ✔ **4: final** |
| 11 | Master and package | All formats, loops, stills, a renders note, cost report | — |

### To prove first, before any film work
1. **Transparent frame export.** Add the export mode and confirm clean edges, a correct soft shadow on light and dark grounds, and identical output on a second run.
2. **The extras.** Redraw the z's, dots, notes, "?" and glow in the film so they match the app.
3. **The desktop.** Vertex needs something to float over. Recommended: a plain drawn window with no real app's interface in it. The alternative is your own screen recording.

### Honesty rules for the film
- No claim the README does not make. The only numbers allowed are the README's own.
- Say what it works with: Claude Code on a Mac. Not the Claude website or the desktop chat app.
- Vertex Buddy is an independent project. No Anthropic logo, and nothing that suggests it is an Anthropic product.

---

## 6. Decisions for you

1. **Concept:** the B + C mix above, or another.
2. **The opening line.** Start on the README's first sentence (recommended), or approve one new line that states the problem.
3. **Lead character.** Cozy Vertex throughout with the other three in the burst (recommended), or equal time for all four.
4. **Music:** a track you license, a generated one (needs a sign-in), or a scratch bed for now.
5. **Where it launches:** GitHub, LinkedIn, both. This sets which version is made first.
6. **Before launch, outside the film:**
   - version 2 is on the branch `vertex-buddy-v2`; the repository's front page still shows version 1;
   - there is no download yet, only "build it yourself", so the end card can only say "on GitHub";
   - the app is called ClaudeBuddy in its files and Vertex Buddy in the README; the film should use one name.

---

## 7. The future plugin

Pixels to Prompt already sketched it as "video-master": a `/video` orchestrator with agents for mining the story, adapting the script, storyboarding, capturing, sourcing sound, composing and verifying, mirroring design-master piece for piece. That sketch stands.

**What Vertex adds:** the source is not always a website. The plugin needs a first step that accepts three kinds of source and turns each into the same line bank and footage plan:

| Source | Copy comes from | Footage comes from | First test case |
|---|---|---|---|
| A design-master build | The build's copy files | Recording the site | Pixels to Prompt, FORMA |
| A live address | The page text | Recording the page | — |
| An app with a README | The README | The app's own renderer, or supplied recordings | Vertex Buddy |

Everything after that step (concept, script, storyboard, build, check, package) stays the same.

---

## Sources
- HyperFrames: [github.com/heygen-com/hyperframes](https://github.com/heygen-com/hyperframes), [claude.com/plugins/hyperframes](https://claude.com/plugins/hyperframes), [developers.heygen.com/hyperframes-overview](https://developers.heygen.com/hyperframes-overview)
- Remotion skills and licence: [remotion.dev/docs/ai/skills](https://www.remotion.dev/docs/ai/skills), [remotion.dev/docs/license/pricing](https://www.remotion.dev/docs/license/pricing), [remotion.dev/docs/license/faq](https://www.remotion.dev/docs/license/faq)
- Higgsfield: [higgsfield.ai/blog/Generate-AI-Videos-From-Claude-with-Higgsfield-MCP](https://higgsfield.ai/blog/Generate-AI-Videos-From-Claude-with-Higgsfield-MCP)
- ElevenLabs: [elevenlabs.io/blog/introducing-voice-music-image-and-video-generation-in-the-elevenlabs-mcp](https://elevenlabs.io/blog/introducing-voice-music-image-and-video-generation-in-the-elevenlabs-mcp)
- Roundups, some written by the tool makers themselves: [hyperframes.heygen.com/blog/best-claude-code-skills-for-video](https://hyperframes.heygen.com/blog/best-claude-code-skills-for-video), [claudevideo.org/guides/hyperframes-remotion-claude-code](https://claudevideo.org/guides/hyperframes-remotion-claude-code)
- On this Mac: `../FORMA/video/README.md`, `../FORMA/video/docs/research.md`, `../untitled folder/pixels-to-prompt-practise-5/VIDEO-PLAN.md`
