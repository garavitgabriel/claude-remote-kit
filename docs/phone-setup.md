# Phone setup (Termius + Tailscale)

The phone side is ~10 minutes, all in two apps. `/remote-setup` walks you
through this interactively; this doc is the standalone version.

## 1. Tailscale on the phone

Install Tailscale (iOS/Android), sign in to the **same tailnet** as your
host, and toggle the VPN on. That's it — your phone can now reach your
machines by name from any network, with no ports exposed to the internet.

Check: in the Tailscale app you should see your host machine listed. Note its
**MagicDNS name** (something like `my-desktop` — on the host, `tailscale
status` prints it).

## 2. Termius base host

Install [Termius](https://termius.com) (free tier is enough).

Add a Host:
- **Address**: the host's MagicDNS name (not an IP — names survive
  re-registration, IPs go stale)
- **Username**: your login on the host
- **Auth**: add/generate an SSH key in Termius and add its public half to
  the host's `~/.ssh/authorized_keys` (Termius can export the pubkey; or use
  password auth to bootstrap, then `ssh-copy-id` equivalent later)

Tap it. You should land in a shell on your host. If not:

| Symptom | Cause | Fix |
|---|---|---|
| Timeout | Tailscale off on either end | toggle both on |
| Connection refused | host's SSH server off | macOS: System Settings → General → Sharing → **Remote Login** (ships disabled). Linux: `sudo systemctl enable --now ssh` |
| Password prompt | key not on host | append Termius pubkey to host's `~/.ssh/authorized_keys` |
| Permission denied | key **or wrong username** | verify with `whoami` on the host — this one masquerades as a key problem |

## 3. One tile per project (the whole trick)

Don't make one host with many snippets — **duplicate the host once per
project** and give each copy a *startup snippet*:

```
cd ~/projects/my-app && tm
```

Rename each tile to the project. Your Termius host list becomes a launcher:

```
┌─────────────────────────┐
│  ▶ my-app               │   ← tap = my-app's live Claude session
│  ▶ my-other-thing       │
│  ▶ blog                 │
└─────────────────────────┘
```

Because `tm` is deterministic (folder name → session name), tapping a tile
always lands in *that project's* one true session — created if it's the
first time, resumed forever after.

## 4. Living with it

- **Scrolling: use Termius's native Scroll button.** Touch-swiping through
  tmux is a protocol mismatch (swipes register as cursor moves); it is not
  fixable with config and not worth your evening. This is the #1 "is it
  broken?" report and the answer is no — wrong tool, use the button.
- **Keyboard**: Termius's extra key row has Ctrl and arrows — `Ctrl-B d`
  (detach) and `Ctrl-B s` (session tree) work fine on glass.
- **Don't exit, detach.** `exit` in the shell kills the session; detach (or
  just leave the app) keeps it alive.
- The status line inside Claude Code is sized for this: model, project,
  context bar, rate-limit window — a glance tells you whether to fire off
  the next big task or wait for the reset.
