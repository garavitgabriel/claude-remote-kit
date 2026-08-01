# Daily driving

The mental model: **the host is the workspace, devices are viewports.**
Nothing you do on a phone or laptop starts or stops work — it just looks at
work that lives on the host.

## Start

```bash
cd ~/projects/my-app
tm          # attach to (or create) the session named "my-app"
claude      # start Claude inside tmux — ALWAYS inside tmux
```

`tm` is deterministic: same folder → same session name → same session. You
cannot accidentally end up with two sessions for one project unless you ask
for it (`tm2`).

Forgot to start inside tmux? The rescue dance: `/exit` Claude → `tm` →
`claude` → `/resume` and pick the conversation. Claude Code conversations are
resumable; the tmux wrapper is what makes them *reachable*.

## Walk away

- `Ctrl-B d` — detach. Session keeps running.
- Or just close the terminal app / put the laptop away. Same thing.
- Long-running Claude tasks (builds, refactors, agents) continue on the host.

## Come back

| From | Do |
|---|---|
| Phone | Tap the project's Termius tile |
| Laptop | `ssh yourhost-tmux` (lands in whatever session its `RemoteCommand` names — point it at your daily project) or `ssh yourhost` then `cd project && tm` |
| The host itself | `cd project && tm` |

You land in the same scrollback, same Claude conversation, mid-thought.

## Parallel sessions

- `tm2` — second session on the same project (`my-app-2`), e.g. Claude in
  one, tests/logs in the other. `tm2 logs` names it `my-app-logs`.
- `Ctrl-B s` — tree of every session and window, by name. This is your map.
- `Ctrl-B ,` — rename the current window. Names stick (the config disables
  auto-renaming, otherwise Claude windows all rename themselves to Claude's
  version number).
- `Ctrl-B J` / `Ctrl-B B` — join a window in as a split pane / break a pane
  back out.

## Read the status line

```
Fable 5 | my-app | ████████░░ 80% | ⏱ 34% ↻ 3:00pm
```

- **Context bar** — scaled so full ≈ auto-compaction imminent. When it's
  nearly full, finish the thought or `/compact` on your own terms instead of
  mid-task.
- **⏱ n% ↻ time** — how much of the 5-hour usage window is burned and when
  it resets. The thing you check from your phone before deciding whether to
  fire off a big task.

## Scrolling & copying

- Desktop terminals: mouse wheel scrolls, drag-select copies to clipboard
  (release keeps the view frozen until `q`).
- **Termius iOS: use the native Scroll button**, not swipes. tmux + touch
  swiping is a protocol mismatch; it will never feel right, stop tuning it.

## Hygiene

Weekly: `tmux ls`, kill what's dead (`tmux kill-session -t old-thing`).
Zombie sessions are the tax on this workflow; without pruning you'll have 15
of them and no idea which is live.

**Which session was I in?** Don't trust creation time. Inventory:

```bash
tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name} #{pane_current_path}'
tmux capture-pane -p -t some-session:1 | tail   # peek at its last screen
```

**Window looks phone-sized on your desktop?** A stale client is still
attached: `tmux attach -d -t name` (`-d` kicks the others).

## When it breaks

`/remote-setup doctor` in Claude Code, or `bash doctor.sh` from the repo.
Every check prints its fix.

## Reading artifacts away from the keyboard

If your sessions write markdown/HTML you want to *read* on the phone (briefs,
reports, review queues), a terminal is the wrong surface — push them to
[Marknote](https://marknote.app) and read them in a mobile inbox instead.
