# Vertex Buddy

Vertex is a little pixel cloud that floats above every app on your Mac (every Space, full-screen
apps too) and tells you when a Claude Code session is waiting for you. Its colour shows its mood
at a glance:

| Vertex looks… | Colour | Meaning |
|---|---|---|
| Asleep, soft z's drifting up | Lavender | No Claude sessions running |
| Calm, blinking | Sky blue | Sessions open, nothing to do |
| Glancing, bouncing dots | Green | Claude is working |
| Happy eyes, waving, soft glow | Sunny yellow | A session finished: your turn |
| Wide eyes, both arms waving, pulsing glow | Rose pink | A session needs your answer (permission prompt or question) |

A name tag under Vertex shows the same colour and what it's doing. The dots, z's and glow are
smooth Core Animation layers. The window server animates them itself, so Vertex stays below
1% CPU.

When something new is waiting it hops, chimes, and pops a speech bubble for 15 seconds.
It then folds back to just the badge and reminds you again every 5 minutes until you respond.

## Use it

- **Click the buddy**: jumps to the waiting session (permission prompts first). In VS Code,
  Cursor and Windsurf it focuses the window with that project open. In Terminal and iTerm it
  selects the right tab.
- **Hover**: shows the bubble with every session and its status. Click a row to jump to it, or × to dismiss it.
- **Drag**: move it anywhere. The position is remembered.
- **Right-click**: sessions list, Dismiss all, Sound, Remind me (off / 2 / 5 / 10 min),
  Open at login, Quit.

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
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --status      # print what it sees right now
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --demo        # fake waiting sessions to preview the UI
build/ClaudeBuddy.app/Contents/MacOS/ClaudeBuddy --snapshot /tmp/buddy   # render every pose to PNG
```

The sprite is a plain text grid in `Sources/ClaudeBuddy/Sprite.swift`; edit the characters to change the art.
Mood colours live in the `Mood` enum in the same file, and the name is `Buddy.name` in `Effects.swift`.
