#!/usr/bin/env bash
set -euo pipefail

BANNER=$'🌌 Neon Tidy — Cosmic Cleanup Console\n'
BANNER+=$'-------------------------------------\n'
BANNER+=$'Pulse, purge, and power up.\n'

idle_minutes_default=45

log_file="${HOME:-/tmp}/.neon_tidy.log"

log() {
  printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$log_file"
}

temp_dir() {
  echo "${TEMP:-${TMPDIR:-/tmp}}"
}

human_bytes() {
  local bytes=$1
  local unit=B
  local step=1024
  local value=$bytes
  for next in KB MB GB TB; do
    if (( value < step )); then
      break
    fi
    value=$(( value / step ))
    unit=$next
  done
  printf '%s %s' "$value" "$unit"
}

confirm() {
  local prompt=$1
  read -r -p "$prompt [y/N]: " choice
  case "${choice,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

system_status() {
  echo ""
  echo "🌠 System Pulse"
  local tdir
  tdir=$(temp_dir)
  local size
  size=$(du -sk "$tdir" 2>/dev/null | awk '{print $1}')
  size=$(( size * 1024 ))
  echo "Temp path: $tdir"
  echo "Temp size: $(human_bytes "$size")"
  echo ""
  echo "Top CPU processes:"
  ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "  PID %6s | %-25s | %s%% CPU\n", $1, $2, $3}'
  log "Viewed system pulse"
}

clean_temp() {
  echo ""
  echo "🧼 Photon Wash"
  local tdir
  tdir=$(temp_dir)
  local size
  size=$(du -sk "$tdir" 2>/dev/null | awk '{print $1}')
  size=$(( size * 1024 ))
  echo "Temp folder: $tdir"
  echo "Current size: $(human_bytes "$size")"
  if ! confirm "Blast temp files?"; then
    echo "Cancelled."
    return
  fi
  local removed=0
  while IFS= read -r -d '' file; do
    if rm -f "$file" 2>/dev/null; then
      removed=$(( removed + 1 ))
    fi
  done < <(find "$tdir" -type f -print0 2>/dev/null)
  local size_after
  size_after=$(du -sk "$tdir" 2>/dev/null | awk '{print $1}')
  size_after=$(( size_after * 1024 ))
  echo "Removed files: $removed"
  echo "New size: $(human_bytes "$size_after")"
  log "Cleaned temp files ($removed removed)"
}

parse_ps_time() {
  local value=$1
  local days=0
  local time_part=$value
  if [[ "$value" == *-* ]]; then
    days=${value%%-*}
    time_part=${value#*-}
  fi
  IFS=: read -r a b c <<< "$time_part"
  if [[ -z ${c:-} ]]; then
    c=$b
    b=$a
    a=0
  fi
  if [[ -z ${b:-} ]]; then
    b=$a
    a=0
  fi
  echo $(( days * 86400 + a * 3600 + b * 60 + c ))
}

idle_candidates() {
  local threshold=$1
  ps -eo pid,comm,etime,time | tail -n +2 | while read -r pid comm etime cputime; do
    local elapsed
    elapsed=$(parse_ps_time "$etime")
    local cpu
    cpu=$(parse_ps_time "$cputime")
    if (( elapsed - cpu >= threshold )); then
      printf "  PID %6s | %-25s | idle ~%sm\n" "$pid" "$comm" $(( elapsed / 60 ))
    fi
  done
}

hibernate_idle() {
  echo ""
  echo "🛸 Hibernation Dock"
  read -r -p "Idle minutes threshold [${idle_minutes_default}]: " minutes
  local threshold=${minutes:-$idle_minutes_default}
  local threshold_seconds=$(( threshold * 60 ))
  local results
  results=$(idle_candidates "$threshold_seconds")
  if [[ -z "$results" ]]; then
    echo "No idle apps detected."
    return
  fi
  echo "Possible idle apps:"
  echo "$results"
  if confirm "Terminate all listed processes?"; then
    while read -r line; do
      local pid
      pid=$(awk '{print $2}' <<< "$line")
      kill -9 "$pid" 2>/dev/null && echo "Closed PID $pid." || echo "Could not close PID $pid."
    done <<< "$results"
    log "Terminated idle processes"
  fi
}

focus_mode() {
  echo ""
  echo "🎧 Focus Mode"
  read -r -p "Process name to keep (pattern): " keep
  if [[ -z "$keep" ]]; then
    echo "No pattern provided."
    return
  fi
  local pids
  pids=$(pgrep -f "$keep" || true)
  if [[ -z "$pids" ]]; then
    echo "No processes match '$keep'."
    return
  fi
  echo "Lowering priority for everything except '$keep'."
  ps -eo pid,comm | tail -n +2 | while read -r pid comm; do
    if [[ "$pids" != *"$pid"* ]]; then
      renice 10 -p "$pid" >/dev/null 2>&1 || true
    fi
  done
  log "Entered focus mode for pattern: $keep"
}

launch_app() {
  echo ""
  echo "🚀 Launch Orbit"
  read -r -p "Enter command: " cmd
  if [[ -z "$cmd" ]]; then
    echo "No command provided."
    return
  fi
  nohup bash -c "$cmd" >/dev/null 2>&1 &
  echo "Launched."
  log "Launched command: $cmd"
}

print_menu() {
  echo "$BANNER"
  echo "[1] System pulse - Top CPU users + temp size."
  echo "[2] Photon wash - Clean temp files."
  echo "[3] Hibernation dock - Find & close idle apps (45+ minutes)."
  echo "[4] Focus mode - Deprioritize everything except a chosen app."
  echo "[5] Launch orbit - Run a command."
  echo "[L] View log - See actions taken."
  echo "[Q] Quit - Exit Neon Tidy."
}

show_log() {
  echo ""
  echo "📜 Session Log: $log_file"
  if [[ -f "$log_file" ]]; then
    tail -n 50 "$log_file"
  else
    echo "No log entries yet."
  fi
}

main() {
  print_menu
  while true; do
    read -r -p $'\nSelect option: ' choice
    case "${choice^^}" in
      1) system_status ;;
      2) clean_temp ;;
      3) hibernate_idle ;;
      4) focus_mode ;;
      5) launch_app ;;
      L) show_log ;;
      Q|QUIT|EXIT) echo "Drift easy. ✨"; break ;;
      *) echo "Unknown choice. Try again." ;;
    esac
  done
}

main
