# claude-remote-kit — shell layer (bash + zsh compatible)
# Sourced from your ~/.zshrc or ~/.bashrc by install.sh. Nothing here runs
# unless you call it — except the SSH auto-attach block at the bottom, which
# only fires on interactive SSH logins.

# tmux session per folder. `tm` (no args) attaches to / creates a session
# named after the current dir's basename. `tm name` overrides the name.
# Idempotent: running `tm` from the same folder always lands in the same
# session, so accidental duplicate sessions are impossible.
tm() {
    command -v tmux >/dev/null 2>&1 || { echo "tmux not installed"; return 1; }
    local name="${1:-$(basename "$PWD")}"
    name="${name//./-}"
    name="${name//:/-}"
    name="${name// /-}"
    if [ -n "$TMUX" ]; then
        tmux has-session -t "$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$PWD"
        tmux switch-client -t "$name"
    else
        tmux attach -t "$name" 2>/dev/null || tmux new -s "$name" -c "$PWD"
    fi
}

# Sibling tmux session: same folder, different name. For when you want a
# second Claude conversation on the same project without mirroring the first.
# `tm2`        → <folder>-2 (auto-increments: -2, -3, -4 if names taken)
# `tm2 logs`   → <folder>-logs (explicit suffix)
tm2() {
    command -v tmux >/dev/null 2>&1 || { echo "tmux not installed"; return 1; }
    local base
    base="$(basename "$PWD")"
    base="${base//./-}"; base="${base//:/-}"; base="${base// /-}"
    local suffix="${1:-}"
    local name
    if [ -n "$suffix" ]; then
        name="${base}-${suffix}"
    else
        local n=2
        while tmux has-session -t "${base}-${n}" 2>/dev/null; do n=$((n+1)); done
        name="${base}-${n}"
    fi
    if [ -n "$TMUX" ]; then
        tmux has-session -t "$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$PWD"
        tmux switch-client -t "$name"
    else
        tmux attach -t "$name" 2>/dev/null || tmux new -s "$name" -c "$PWD"
    fi
}

# Auto-attach on interactive SSH login: lands you in a session named after
# wherever you land. Guards, in order:
#   -z $TMUX            don't nest inside an existing tmux
#   $- == *i*           interactive shells only — scp/rsync/git keep working
#   -n $SSH_CONNECTION  SSH sessions only — local terminals stay plain
#                       (delete this guard if you want local auto-tmux too)
#   $PWD != $HOME       skip plain-home landings, so a bare `ssh host` gives a
#                       normal shell and doesn't spawn a session named after
#                       your username. Use the <host>-tmux SSH alias (see
#                       ssh-config.example) when you want to land in tmux.
case $- in *i*)
    if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ] && [ "$PWD" != "$HOME" ]; then
        tm
    fi
;; esac

# TERM fallback: downgrade to a known TERM when the terminfo entry is missing
# (fixes "missing or unsuitable terminal" when SSHing in from terminals the
# host doesn't know about, e.g. Ghostty's xterm-ghostty)
if command -v infocmp >/dev/null 2>&1 && ! infocmp "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi
