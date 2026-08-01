#!/usr/bin/env bash
# claude-remote-kit — doctor
# Verifies the postconditions of a working remote setup, in the vocabulary of
# the task (does the session actually exist? does port 22 actually answer?) —
# not just "did the installer exit 0". Every FAIL prints its fix.
#
# Run: bash doctor.sh
set -u

PASS=0; FAIL=0; WARN=0

ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n       fix: %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
meh()  { printf '  \033[33mWARN\033[0m %s\n       %s\n' "$1" "$2"; WARN=$((WARN+1)); }

echo "== host basics =="

if command -v tmux >/dev/null 2>&1; then
  ok "tmux installed ($(tmux -V))"
else
  bad "tmux not installed" "macOS: brew install tmux | Debian/Ubuntu: sudo apt install tmux"
fi

if [ -f "$HOME/.tmux.conf" ] && grep -q "allow-rename off" "$HOME/.tmux.conf"; then
  ok "~/.tmux.conf installed (rename guards present)"
elif [ -f "$HOME/.tmux.conf" ]; then
  meh "~/.tmux.conf exists but isn't the kit's" "run bash install.sh (your file is backed up first)"
else
  bad "~/.tmux.conf missing" "run: bash install.sh"
fi

if [ -f "$HOME/.config/claude-remote-kit/remote-kit.sh" ]; then
  ok "shell layer installed (~/.config/claude-remote-kit/remote-kit.sh)"
else
  bad "shell layer not installed" "run: bash install.sh"
fi

RC_HIT=""
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  [ -f "$rc" ] && grep -q "claude-remote-kit" "$rc" && RC_HIT="$rc" && break
done
if [ -n "$RC_HIT" ]; then
  ok "shell rc sources the kit ($RC_HIT)"
else
  bad "no rc file sources the kit" "run: bash install.sh"
fi

echo "== reachability (the phone path) =="

if command -v tailscale >/dev/null 2>&1 || [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]; then
  TS="tailscale"
  command -v tailscale >/dev/null 2>&1 || TS="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  if "$TS" status >/dev/null 2>&1; then
    ok "tailscale up ($("$TS" status --self=true --peers=false 2>/dev/null | awk '{print $2; exit}'))"
  else
    bad "tailscale installed but not connected" "run: tailscale up (or open the Tailscale app and sign in)"
  fi
else
  bad "tailscale not installed" "https://tailscale.com/download — free for personal use, 'ssh from your phone' transport"
fi

if command -v nc >/dev/null 2>&1; then
  if nc -z -w 2 localhost 22 >/dev/null 2>&1; then
    ok "SSH server answering on port 22"
  else
    if [ "$(uname)" = "Darwin" ]; then
      bad "port 22 not answering — Remote Login is off" "System Settings → General → Sharing → Remote Login (macOS ships it disabled)"
    else
      bad "port 22 not answering" "install/start openssh-server: sudo apt install openssh-server && sudo systemctl enable --now ssh"
    fi
  fi
else
  meh "nc not available — can't probe port 22" "test from another device: ssh <this-host>"
fi

echo "== live sessions =="

if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
  ok "tmux server running — sessions:"
  tmux list-windows -a -F '       #{session_name}:#{window_index} #{window_name} (#{pane_current_path})' 2>/dev/null
else
  meh "no tmux sessions yet" "cd into a project and run: tm — then detach with Ctrl-B d"
fi

echo "== Claude Code status line =="

if command -v jq >/dev/null 2>&1; then
  ok "jq installed (statusline dependency)"
else
  bad "jq not installed (statusline needs it)" "macOS: brew install jq | Debian/Ubuntu: sudo apt install jq"
fi

if [ -x "$HOME/.claude/statusline-command.sh" ]; then
  ok "statusline script installed + executable"
else
  bad "statusline script missing" "run: bash install.sh"
fi

if [ -f "$HOME/.claude/settings.json" ] && grep -q "statusline-command.sh" "$HOME/.claude/settings.json" 2>/dev/null; then
  ok "settings.json wires the statusline"
else
  meh "statusline not wired in ~/.claude/settings.json" 'add: "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }'
fi

echo
echo "== summary: $PASS pass, $FAIL fail, $WARN warn =="
[ "$FAIL" -eq 0 ] && echo "Host side looks good. Final proof is end-to-end: from your phone (Termius), tap your host tile and watch your session appear."
exit "$FAIL"
