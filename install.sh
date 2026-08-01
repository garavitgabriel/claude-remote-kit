#!/usr/bin/env bash
# claude-remote-kit — installer
#
# Safe by design:
#   - Anything it would overwrite is backed up first (*.bak-<timestamp>)
#   - Your shell rc is APPENDED to (one marked source line), never replaced
#   - Your SSH config and Claude settings.json are NEVER touched — those are
#     personal; the /remote-setup skill (or docs/) guides you through them
#
# Run: bash install.sh          (from the repo root)
# The interactive path — open Claude Code here and say /remote-setup — does
# this and more, adapted to your machine.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
KIT_HOME="$HOME/.config/claude-remote-kit"

place() { # place <src> <dest>
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && ! cmp -s "$src" "$dest"; then
    cp "$dest" "$dest.bak-$STAMP"
    echo "  backup: $dest -> $dest.bak-$STAMP"
  fi
  cp "$src" "$dest"
  echo "  installed: $dest"
}

echo "== shell layer (tm, tm2, SSH auto-attach) =="
mkdir -p "$KIT_HOME"
place "$KIT/config/shell/remote-kit.sh" "$KIT_HOME/remote-kit.sh"
# Record where the repo lives so the globally-installed skill can find
# doctor.sh and the config templates later.
echo "$KIT" > "$KIT_HOME/kit-path"

# Append one marked source line to the right rc file — idempotent.
case "${SHELL:-}" in
  */zsh)  RC="$HOME/.zshrc" ;;
  */bash) RC="$HOME/.bashrc" ;;
  *)      RC="$HOME/.profile" ;;
esac
SOURCE_LINE='[ -f "$HOME/.config/claude-remote-kit/remote-kit.sh" ] && . "$HOME/.config/claude-remote-kit/remote-kit.sh"  # claude-remote-kit'
if [ -f "$RC" ] && grep -q "claude-remote-kit" "$RC"; then
  echo "  already sourced from $RC"
else
  printf '\n%s\n' "$SOURCE_LINE" >> "$RC"
  echo "  added source line to $RC"
fi

echo "== tmux config =="
if command -v tmux >/dev/null 2>&1; then
  place "$KIT/config/tmux.conf" "$HOME/.tmux.conf"
  # Apply to a running tmux server too, so you don't need to restart sessions
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null && echo "  reloaded running tmux server" || true
else
  echo "  SKIP — tmux not installed."
  echo "         macOS: brew install tmux   |   Debian/Ubuntu: sudo apt install tmux"
fi

echo "== Claude Code status line =="
mkdir -p "$HOME/.claude"
place "$KIT/config/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
chmod +x "$HOME/.claude/statusline-command.sh"
if command -v jq >/dev/null 2>&1 && [ -f "$HOME/.claude/settings.json" ] && jq -e '.statusLine' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
  echo "  settings.json already has a statusLine — left untouched"
else
  echo "  To activate it, add this to ~/.claude/settings.json:"
  echo '    "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }'
  echo "  (or let /remote-setup wire it for you)"
fi

echo "== remote-setup skill (global) =="
# Copy the skill to ~/.claude/skills so /remote-setup (and its doctor mode)
# works from ANY project session, not just inside this repo. Re-running
# install.sh refreshes it.
mkdir -p "$HOME/.claude/skills/remote-setup"
place "$KIT/.claude/skills/remote-setup/SKILL.md" "$HOME/.claude/skills/remote-setup/SKILL.md"

echo "== SSH host aliases (not auto-installed) =="
echo "  Template: $KIT/config/ssh-config.example"
echo "  Copy the blocks you want into ~/.ssh/config — or run /remote-setup"
echo "  in Claude Code to have it built for your machines interactively."

echo
echo "Done. Open a new shell (or: source $RC), then run: bash $KIT/doctor.sh"
