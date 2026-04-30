#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/root/data/drinkWater}"
PYTHON_BIN="${PYTHON_BIN:-$PROJECT_DIR/venv/bin/python3}"
CRON_LOG="${CRON_LOG:-$PROJECT_DIR/cron.log}"

MARKER_BEGIN="# BEGIN drinkWater cron"
MARKER_END="# END drinkWater cron"

if [ ! -x "$PYTHON_BIN" ]; then
  echo "Python interpreter not found or not executable: $PYTHON_BIN" >&2
  exit 1
fi

if [ ! -f "$PROJECT_DIR/simple_reminder.py" ]; then
  echo "simple_reminder.py not found in: $PROJECT_DIR" >&2
  exit 1
fi

current_cron="$(mktemp)"
next_cron="$(mktemp)"
trap 'rm -f "$current_cron" "$next_cron"' EXIT

crontab -l 2>/dev/null > "$current_cron" || true

awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
  $0 == begin { skip = 1; next }
  $0 == end { skip = 0; next }
  skip { next }
  /\/root\/data\/drinkWater\/simple_reminder\.py/ { next }
  { print }
' "$current_cron" > "$next_cron"

if [ -s "$next_cron" ]; then
  printf '\n' >> "$next_cron"
fi

{
  printf '%s\n' "$MARKER_BEGIN"
  printf '* 9-11 * * * %s %s/simple_reminder.py >> %s 2>&1\n' "$PYTHON_BIN" "$PROJECT_DIR" "$CRON_LOG"
  printf '* 14-17 * * * %s %s/simple_reminder.py >> %s 2>&1\n' "$PYTHON_BIN" "$PROJECT_DIR" "$CRON_LOG"
  printf '%s\n' "$MARKER_END"
} >> "$next_cron"

crontab "$next_cron"

echo "Installed drinkWater cron entries:"
crontab -l | sed -n "/$MARKER_BEGIN/,/$MARKER_END/p"
