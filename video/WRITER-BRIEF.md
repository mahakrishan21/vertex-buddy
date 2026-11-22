# Vertex Buddy launch film: brief for the scriptwriter

## What I need from you

A more detailed script for a short launch film about a small Mac app called Vertex Buddy. A first cut of the film already exists (45.6 seconds, no voiceover). Its script is in section 6. I would like you to rewrite and expand it: stronger opening, clearer story, better lines, and a decision on whether it should have a voice.

Everything you need to know about the product is in this document. You do not need to install anything.

## 1. The product in one paragraph

Vertex Buddy is a little 3D character that floats on top of every app on a Mac. It watches the Claude Code sessions running on that Mac and shows, by its colour and behaviour, what they are doing. When a session finishes or stops to ask a question, Vertex hops, chimes and pops a speech bubble, so you notice straight away. Clicking Vertex takes you to the session that is waiting.

Claude Code is an AI coding assistant made by Anthropic. People give it a task, it works for a while by itself, and it stops either when it is done or when it needs permission or an answer.

## 2. Who it is for, and the problem it solves

**Who:** people who use Claude Code on a Mac, mostly developers and designers, often with several sessions running at once in different projects.

**The problem:** you give Claude a task and switch to something else while it works. Minutes later it has finished, or it is waiting for you to approve a command, and you have not noticed. The session sits idle until you happen to look. With several sessions open it is worse: you do not know which one needs you.

Note: the README never states this problem in words. It only says what Vertex does about it. The current film therefore does not state it either. Whether the new script may open on the problem is one of the open questions in section 9.

## 3. The facts you can use

These are true of the app today. Please do not go beyond them.

### What it does
- Floats above every app, on every Space, including full-screen apps.
- Shows every live Claude Code session with its status, the app it runs in, and how long it has been in that state.
- Tells you the state by colour, readable at a glance:

| Colour | Meaning |
|---|---|
| Dim lavender | Asleep: no Claude sessions running |
| Aqua | Sessions open, nothing to do |
| Green | Claude is working |
| Sunny yellow | A session finished: your turn |
| Rose pink | A session needs your answer (a permission prompt or a question) |

- When something new is waiting it hops, chimes, and pops a speech bubble for 15 seconds. It then reminds you again every 5 minutes until you respond.
- A waiting session always comes first, even if you have told Vertex to do something else, "because telling you is the whole point."

### How you use it
- **Hover:** opens the bubble with every session. The one Vertex is reacting to is outlined.
- **Click:** jumps to the waiting session. In VS Code, Cursor and Windsurf it brings forward the window with that project. In Terminal and iTerm it selects the right tab.
- **Drag:** pick it up and put it anywhere. It remembers the spot.
- **Right-click:** choose the character, choose a behaviour, turn sound and reminders on or off.

### How it knows
- Claude Code already writes each session's state to a small file on the Mac. Vertex reads those files once a second.
- It needs no hooks and no changes to Claude settings. It only reads the files and never writes them.
- Nothing is sent anywhere.

### The four characters
All four do every behaviour and pull every face. Only the body differs.

| Name | What it is |
|---|---|
| Cloud Vertex | The original little cloud, as a soft toy. Its whole body takes the status colour. It floats instead of walking. |
| Pixel Vertex | A flat pixel-art robot with a screen for a head. |
| Robo Vertex | A 3D robot with a boxy head and a glass screen. |
| Cozy Vertex | The one in the hoodie: charcoal hood, glossy black face screen, neon-green headphones. This is the default and the lead in the film. |

### The nine behaviours
"Auto" is the default: the live sessions decide what Vertex does. You can also pin any one of these.

| Behaviour | What Vertex does |
|---|---|
| Idle | Breathes, blinks, glances aside, shifts its weight, taps a foot, yawns and stretches, gives a little wave |
| Working | Leans in with a determined frown, eyes sweeping along the line, hands typing, a foot tapping; stops now and then with a hand to its chin |
| Thinking | Gaze drifts up with a hand to the chin, thought dots rise; sometimes scratches its head, sometimes an "aha" hop with both arms up |
| Walking | Turns to face where it is going and strolls a short way from where you parked it, then comes back. Four gaits: walk, tiptoe, skip, run |
| Following | Head and eyes follow your cursor; it points toward it and throws its arms up when the cursor comes close |
| Watching | Hands behind its back, looks around, leans in to inspect, does surprised double-takes, reaches for a passing firefly |
| Sleeping | Yawns, sits down with its feet out, head sinks forward, breathes slowly, z's drift up |
| Happy | Smiling eyes and blush; jumps, dances from foot to foot, twirls, winks and waves, music notes float up |
| Curious | Head on one side with one brow raised, leans over for a peek, stretches up on its toes, a "?" pops up |

### Faces and reactions
- Twelve faces: neutral, happy, excited, curious, confused, sleepy, surprised, playful, focused, worried, pondering, sneaky.
- Its eyes are never quite still.
- It reacts to you: it flails when picked up, lands with its arms out and looks dazed, perks up when you hover, and winks and waves when clicked.

### Limits (please respect these)
- It works with **Claude Code** only. It does not see the Claude website, the Claude desktop chat app, or other AI tools.
- It is a **Mac** app (macOS 14 or later).
- It is an **independent project**. It is not made by Anthropic and must not look or sound as if it were.
- Today it is on GitHub and people build it themselves. There is **no download button yet**, so the film cannot say "download now".
- The address is `github.com/mahakrishan21/vertex-buddy`.

## 4. Tone

The README's own voice: plain, warm, lightly playful, never salesy. Short sentences. British spelling ("behaviour", "colour"). Vertex is called "it". The app is called "Vertex" or "Vertex Buddy".

## 5. What the film is today

- **Format:** 16:9, 1920 × 1080, 45.6 seconds. A vertical version and a 15-second teaser are planned later.
- **Idea:** "a day with Vertex". We follow it from asleep, through working, to a session needing you, and the click that answers it. Then the four characters. Then the name.
- **Style:** large bold type on the left, Vertex on the right, on a light ground. The light behind Vertex takes the status colour, so the five colours are the colour script of the film.
- **No voiceover.** Every line is type on screen, so it reads with the sound off.
- **Sound:** ten small effects (pops, a click, two whooshes). No music yet.
- **Rule used so far:** every sentence on screen is taken word for word from the README. That kept the messaging unchanged, but it also made the film a little flat. You may loosen it (see section 8).

## 6. The current script

### Scene 1. The day (0:00 to 0:26)
One continuous shot. Cozy Vertex stands at the right over a plain app window.

| Time | Label | Words on screen | What Vertex does | Behind it | Sound |
|---|---|---|---|---|---|
| 0:00 | | Vertex is a little 3D buddy that floats above every app on your Mac | Sits asleep, z's drifting up. Lavender light. | A window titled "website" | |
| 0:05 | AQUA | Sessions open, nothing to do | Wakes, stretches, stands. Aqua light. | Same window | |
| 0:08 | GREEN | Claude is working | Leans in and types. Green light. | Lines fill in down the window | |
| 0:11 | | every Space, full-screen apps too | Keeps working, stays on top. | Another app takes the window's place, then goes full screen | |
| 0:14 | SUNNY YELLOW | A session finished: your turn | Smiles and waves. Yellow light. The speech bubble pops: "Your turn · website". | Full-screen app | Pop |
| 0:20 | ROSE PINK | A session needs your answer | Wide eyes, arms out. Pink light. Bubble changes to "Needs you · api". | Full-screen app | Pop |
| 0:22 | | Click the buddy: jumps to the waiting session | A large cursor comes in and clicks Vertex. It winks, then goes back to work. Green light. | The bubble closes and the "api" window jumps forward | Click, whoosh |

### Scene 2. The cast (0:26 to 0:35)
The four characters in a row with their names. They change behaviour together; a label names each one.

| Time | Words on screen | Behaviour label | Sound |
|---|---|---|---|
| 0:26 | Vertex comes as four characters. | Idle | |
| 0:28 | | Working | Pop |
| 0:30 | They all do every behaviour and pull every face; only the body differs. | Happy | Pop |
| 0:32 | | Curious | Pop |
| 0:34 | | Thinking | Pop, whoosh |

### Scene 3. The close (0:35 to 0:46)

| Time | Words on screen | What Vertex does | Sound |
|---|---|---|---|
| 0:35 | It needs no hooks and no changes to Claude settings, and only reads the files, never writes them. | Stands calmly, looking around. Aqua light. | |
| 0:40 | telling you is the whole point. | Jumps and twirls. Yellow light. | |
| 0:43 | Vertex Buddy | Slides left; the name wipes in beside it. | Pop |
| 0:43.5 | github.com/mahakrishan21/vertex-buddy | Winks and waves. Holds to the end. | |

### Where the current script is weak
- It opens on a description, not on a reason to care.
- The viewer is never told why a waiting session matters.
- Scene 2's second line is long for the time it has.
- The trust line in scene 3 is 19 words, the longest in the film.
- "telling you is the whole point." lands without a set-up, because the README sentence it comes from was cut.

## 7. What can be shown on screen

Vertex in the film is the real app, recorded from it. That means:

**Can be shown**
- Any of the four characters doing any of the nine behaviours, in any order, for any length of time.
- The reactions: waking up, being clicked (wink and wave), being picked up and dropped.
- Any of the twelve faces as a close-up.
- The real speech bubble, with any made-up session names and states (for example "website: finished, your turn", "api: needs you").
- A large cursor that clicks things.
- Plain drawn windows behind Vertex, standing in for "an app".
- The status colour as light behind Vertex.

**Cannot be shown**
- Real screens of VS Code, Terminal, Claude or any other product. Windows behind Vertex are plain drawings.
- People, hands, desks or rooms. There is no filmed or generated footage.
- Anything Vertex does not actually do (for example speaking, or reacting to the Claude website).

## 8. Rules for the new script

1. **You may write new lines.** They must be true to section 3. Mark each new line with **[new]** so it can be approved. Lines taken from the current script need no mark.
2. **No numbers except these:** four characters, nine behaviours, twelve faces, five colours, 15 seconds (bubble), every 5 minutes (reminder), once a second (how often it reads).
3. **No claims about speed, productivity or time saved.**
4. **Readable with the sound off.** Even if you add a voice, the key words must also be on screen.
5. **Line length:** 12 words or fewer per line where you can. Allow about 3 words per second of screen time, and never less than 2 seconds for a line.
6. **Length:** 30 to 60 seconds for the main film. Say if you think a different length is right.
7. **The ending** must show the name "Vertex Buddy" and the GitHub address, and cannot promise a download.

## 9. Open questions you can help decide

1. Should the film open on the problem ("you looked away, and Claude has been waiting") before introducing Vertex?
2. Should it have a voiceover? If yes, whose voice: a narrator, or the maker speaking in the first person?
3. Is "a day with Vertex" the right spine, or is there a stronger one?
4. What should the last line be?
5. What kind of music would suit it?

## 10. What to send back

Please use the same table layout as section 6, one row per line:

| Time | Words on screen | Voice (if any) | What Vertex does | Behind it | Sound |
|---|---|---|---|---|---|

Along with it:
- a one-paragraph summary of the idea;
- the full list of lines in order, with **[new]** marks;
- your answers to the questions in section 9;
- if you can, a shorter 15-second version using lines from the main script.
