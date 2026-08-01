#!/usr/bin/env bash
# claude-remote-kit — Claude Code status line
# Shows: model | folder | context bar | 5-hour rate-limit usage + reset time.
#
# The context bar is scaled so 80% real usage displays as 100% — Claude Code
# auto-compacts around there, so the bar hitting full means "compaction is
# imminent", which is the thing you actually want to know.
#
# Wire it up in ~/.claude/settings.json:
#   "statusLine": { "type": "command",
#                   "command": "bash ~/.claude/statusline-command.sh" }
# Requires jq.

input=$(cat)

command -v jq >/dev/null 2>&1 || { printf 'statusline: jq not installed'; exit 0; }

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
folder=$(basename "$cwd")
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
limit_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
limit_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# ANSI codes
DIM='\033[2m'
RESET='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
ORANGE='\033[38;5;208m'
RED_BLINK='\033[31;5m'
BRIGHT='\033[1m'

if [ -z "$used_pct" ]; then
  # No context info yet
  printf "${DIM}%s${RESET} | ${DIM}%s${RESET}" "$model" "$folder"
  exit 0
fi

# Scale: 80% real = 100% displayed
scaled=$(echo "$used_pct 0.8" | awk '{printf "%.0f", ($1 / $2 > 100 ? 100 : $1 / $2)}')

# Build 10-char block bar. No seq: BSD seq counts DOWN when first > last, so
# `seq 1 0` emits two iterations and the bar grows to 12 chars at 100%.
filled=$(echo "$scaled" | awk '{n = int($1 / 10 + 0.5); if (n > 10) n = 10; print n}')

bar=""
i=0
while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i+1)); done
while [ "$i" -lt 10 ]; do bar="${bar}░"; i=$((i+1)); done

# Pick color based on scaled percentage
if [ "$scaled" -ge 95 ]; then
  color="$RED_BLINK"
  suffix=" 💀"
elif [ "$scaled" -ge 65 ]; then
  color="$ORANGE"
  suffix=""
elif [ "$scaled" -ge 50 ]; then
  color="$YELLOW"
  suffix=""
else
  color="$GREEN"
  suffix=""
fi

# Portable "ISO-8601 or epoch → local HH:MMam" — GNU and BSD date disagree on
# everything, so branch once.
fmt_reset_time() { # fmt_reset_time <resets_at>
  local raw="$1" epoch=""
  if date --version >/dev/null 2>&1; then
    # GNU date parses ISO-8601 and @epoch directly
    case "$raw" in
      *[!0-9]*) epoch=$(date -d "$raw" +%s 2>/dev/null) ;;
      *)        epoch="$raw" ;;
    esac
    [ -n "$epoch" ] && date -d "@$epoch" +"%-I:%M%p" 2>/dev/null | tr 'APM' 'apm'
  else
    # BSD date needs -j -f for parsing and -r for epoch
    case "$raw" in
      *Z)       epoch=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "${raw%%[.Z]*}" +%s 2>/dev/null) ;;
      *[!0-9]*) epoch=$(date -j  -f "%Y-%m-%dT%H:%M:%S" "${raw%%[.+]*}" +%s 2>/dev/null) ;;
      *)        epoch="$raw" ;;
    esac
    [ -n "$epoch" ] && date -r "$epoch" +"%-I:%M%p" 2>/dev/null | tr 'APM' 'apm'
  fi
}

# 5-hour usage window segment: "⏱ 34% ↻ 3:00pm"
usage_seg=""
if [ -n "$limit_pct" ]; then
  limit_int=$(echo "$limit_pct" | awk '{printf "%.0f", $1}')
  if [ "$limit_int" -ge 90 ]; then
    ucolor="$RED_BLINK"
  elif [ "$limit_int" -ge 70 ]; then
    ucolor="$ORANGE"
  elif [ "$limit_int" -ge 50 ]; then
    ucolor="$YELLOW"
  else
    ucolor="$GREEN"
  fi
  reset_str=""
  if [ -n "$limit_reset" ]; then
    t=$(fmt_reset_time "$limit_reset")
    [ -n "$t" ] && reset_str=" ${DIM}↻ $t${RESET}"
  fi
  usage_seg=$(printf " | ${ucolor}⏱ %s%%%s${RESET}%s" "$limit_int" "" "$reset_str")
fi

printf "${DIM}%s${RESET} | ${DIM}%s${RESET} | ${BRIGHT}${color}%s${RESET}${color} %s%%%s${RESET}%b" \
  "$model" "$folder" "$bar" "$scaled" "$suffix" "$usage_seg"
