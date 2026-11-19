# Vertex Buddy

Vertex is a little 3D buddy that floats above every app on your Mac (every Space, full-screen
apps too) and tells you when a Claude Code session is waiting for you. It is a real 3D model, lit
like a toy on a photo table, so its head turns and nods, its arms wave, and its body turns to walk.

## Characters

Vertex comes as four characters. Right-click it and choose one under Pet. They all do every
behaviour and pull every face; only the body differs.

| Character | What it is |
|---|---|
| Cloud Vertex | The original little cloud, rebuilt as a soft toy: a puffy pastel body in the status colour, dark shiny eyes, pink cheeks, a small smile and two little arms. It floats instead of walking. |
| Pixel Vertex | The flat pixel-art robot: screen head, headphones and two legs, drawn on a pixel grid. Being flat, it tilts and steps but does not turn its head or body. |
| Robo Vertex | The 3D robot: a boxy head with a brushed bezel round a glass screen, headphones, and two legs. |
| Cozy Vertex | The one in the hoodie: a soft charcoal hood round a glossy black screen, neon-green headphones, drawstrings and cuffs, stubby arms and soft feet. This is the default. |

The eyes (or, for the cloud, the whole body) and the pool of light at its feet show the status
colour, so you can read the state at a glance. Cozy Vertex's headphones and trim stay neon green,
and switch to the status colour only while a session is waiting for you:

| Glow | Meaning |
|---|---|
| Dim lavender | Asleep: no Claude sessions running |
| Aqua | Sessions open, nothing to do |
| Green | Claude is working |
| Sunny yellow | A session finished: your turn |
| Rose pink | A session needs your answer (permission prompt or question) |

When something new is waiting it hops, chimes, and pops a speech bubble for 15 seconds.
It then folds back to just the badge and reminds you again every 5 minutes until you respond.

## Behaviours

Right-click Vertex and choose one under Behaviour. **Auto** (the default) lets the live sessions
decide; any other choice keeps Vertex doing that until you pick Auto again.

| Behaviour | What Vertex does |
|---|---|
| Idle | Breathes, blinks (sometimes slowly), glances aside, shifts its weight and taps a foot, tilts its head, yawns and stretches, rocks on its heels, gives you a little wave |
| Working | Leans in with a determined frown, eyes sweeping along the line, head nodding, hands typing, a foot tapping; stops now and then with a hand to its chin |
| Thinking | Gaze drifts up to one side with a hand to the chin, thought dots rise; sometimes it gets stuck and scratches its head, sometimes an "aha" hop with both arms up |
| Walking | Turns to face the way it is going, arms swinging, and strolls up to about 110 pt either side of where you parked it, then comes back. Four gaits: walk, tiptoe, skip and run |
| Following | Head and eyes follow your cursor anywhere on screen; it points toward it, gets excited when it darts about, and throws its arms up when it comes close |
| Watching | Hands behind its back, looks around, leans in to inspect, does surprised double-takes, reaches for a passing firefly |
| Sleeping | Yawns and stretches, sits down with its feet out, head sinks forward, breathes slowly, twitches a foot, snuggles down, z's drift up |
| Happy | Smiling eyes and blush; jumps (crouch, spring, arms high, a squash on landing), dances from foot to foot, twirls, winks and waves, wiggles its eyebrows, music notes float up |
| Curious | Head on one side with one brow raised, leans over for a peek, stretches up on its toes, scratches its head when puzzled, a "?" pops up; reacts to your cursor and to sessions changing |

Every behaviour pulls matching faces. There are twelve: neutral, happy, excited, curious, confused,
sleepy, surprised, playful, focused, worried, pondering and sneaky. Each sets the eyes and eyebrows
together, and the head, arms and body move to match. Its eyes are never quite still: they make
tiny darting movements even when it is standing quietly. Vertex also reacts to you: it flails when
picked up, lands with its arms out and looks dazed for a moment, perks up when you hover, and
winks and waves when clicked.

In Auto: a session that needs your answer or has just finished always comes first. Otherwise a busy
session means Working with short Thinking breaks, quiet sessions mean Idle with the odd look around,
tilt of the head or short stroll, and no sessions means Sleeping. A waiting session breaks through a
picked behaviour too, because telling you is the whole point.

## Use it

- **Hover**: opens the bubble: every live session with
  its status, the app it runs in and how long it has been in that state. The session Vertex is
  reacting to is outlined. Click a row to jump to it, or × to dismiss an alert.
- **Click the buddy**: jumps to the waiting session (permission prompts first). In VS Code,
  Cursor and Windsurf it focuses the window with that project open. In Terminal and iTerm it
  selects the right tab. With nothing waiting, a click pins the bubble open.
- **Drag**: pick it up and put it down anywhere. That spot becomes home and is remembered.
- **Right-click**: sessions list, Dismiss all, Pet, Behaviour, Stroll when idle, Sound,
  Remind me (off / 2 / 5 / 10 min), Open at login, Quit.

## How it knows

Claude Code already writes each live session's state to `~/.claude/sessions/<pid>.json`
(`busy`, `idle`, `waiting` + what it's waiting for). The buddy reads those files once a second.
It needs no hooks and no changes to Claude settings, and only reads the files, never writes them.
A session counts as "finished" when it goes from busy to idle; dismissing it or prompting again clears it.

## Build

```bash
./build.sh            # builds build/ClaudeBuddy.app
./build.sh --install  # also copies it to ~/Applications and starts it
```

Debug helpers:

```bash
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --status             # print what it sees right now
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --demo               # fake sessions that change state on a 70 s loop
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --behavior walking   # start pinned to one behaviour
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --look cloud         # show one character: cloud, pixel, robo or cozy
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --snapshot /tmp/buddy   # render every behaviour to PNG
```

## Where things are

- `Robot3D.swift`: the four 3D models (one `build…` function each), their materials and lighting,
  and how a frame poses them. Sizes and colours are plain numbers there. The names are in the
  `Look` enum in `Frame.swift`.
- `Behavior.swift`: the `Behavior` list, the twelve faces, and `BehaviorEngine`, which picks the
  behaviour and works out every frame. Each behaviour is one short function.
- `Frame.swift`: what a frame holds (eyes, brows, head and body angles, feet) and the glow
  colours (`Mood`).
- `Effects.swift`: the floating extras (dots, z's, notes, "?", firefly, glow) and the name
  (`Buddy.name`).
- `BuddyView.swift`: the bubble, session rows and right-click menu.

The model is rendered with SceneKit, once for each new frame and never in between. How often a
new frame is made depends on whether you are likely to be looking: 30 a second while your cursor
is within about 260 pt of Vertex, you are using its bubble, or it has just started something new
(blinks and reactions always get 30); otherwise 15 a second while it is busy, 10 while idle and 6
while asleep. In Activity Monitor that reads as roughly 2–4% CPU most of the day, on the
efficiency cores, and about 5–6% while you are watching it.

`--snapshot` also writes `faces.png`, a sheet of all twelve faces, and `characters-dark.png` and
`characters-light.png`, all four characters in the same six poses. Because the window is drawn by
the GPU, `BUDDY_DUMP=/tmp/frame.png` saves what is really on screen four seconds after launch.
`BUDDY_WATCHED=1` (or `0`) pins the frame rate to the watched (or unwatched) setting for measuring.
