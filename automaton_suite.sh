#!/usr/bin/env bash
set -euo pipefail

BANNER=''
BANNER+=$'⚙️  Automaton Suite — Steel & Silk Edition\n'
BANNER+=$'------------------------------------------\n'
BANNER+=$'System sheen with a CLI gleam.\n'

idle_minutes_default=45

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

snapshot() {
  echo ""
  echo "📊 System Snapshot"
  local tdir
  tdir=$(temp_dir)
  local size
  size=$(du -sk "$tdir" 2>/dev/null | awk '{print $1}')
  size=$(( size * 1024 ))
  echo "Temp path: $tdir"
  echo "Temp size: $(human_bytes "$size")"
  echo ""
  echo "Top memory processes:"
  ps -eo pid,comm,rss --sort=-rss | head -n 6 | tail -n 5 | awk '{printf "  PID %6s | %-25s | %s KB\n", $1, $2, $3}'
}

confirm() {
  local prompt=$1
  read -r -p "$prompt [y/N]: " choice
  case "${choice,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

clean_temp() {
  echo ""
  echo "🧹 Clean Temp Files"
  local tdir
  tdir=$(temp_dir)
  local size
  size=$(du -sk "$tdir" 2>/dev/null | awk '{print $1}')
  size=$(( size * 1024 ))
  echo "Temp folder: $tdir"
  echo "Current size: $(human_bytes "$size")"
  if ! confirm "Proceed with cleanup?"; then
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

close_idle_apps() {
  echo ""
  echo "🛌 Idle App Finder"
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
  fi
}

launch_app() {
  echo ""
  echo "🚀 Launch App"
  read -r -p "Enter command (e.g., 'code', '/usr/bin/top'): " cmd
  if [[ -z "$cmd" ]]; then
    echo "No command provided."
    return
  fi
  nohup bash -c "$cmd" >/dev/null 2>&1 &
  echo "Launched."
}

kill_by_pid() {
  echo ""
  echo "🧨 Terminate by PID"
  read -r -p "PID to terminate: " pid
  if [[ -z "$pid" ]]; then
    echo "No PID provided."
    return
  fi
  if confirm "Terminate PID $pid?"; then
    kill -9 "$pid" 2>/dev/null && echo "Closed PID $pid." || echo "Could not close PID $pid."
  fi
}

lower_priority() {
  echo ""
  echo "🌙 Lower Priority"
  read -r -p "PID to deprioritize: " pid
  if [[ -z "$pid" ]]; then
    echo "No PID provided."
    return
  fi
  if renice 10 -p "$pid" >/dev/null 2>&1; then
    echo "Priority lowered."
  else
    echo "Could not change priority."
  fi
}

print_menu() {
  echo "$BANNER"
  echo "[1] System snapshot - Show memory-hungry processes and temp folder size."
  echo "[2] Clean temp files - Free up space by clearing OS temp files."
  echo "[3] Find & close idle apps - List apps idle for 45+ minutes and optionally close them."
  echo "[4] Launch an app/command - Start a program by typing its command."
  echo "[5] Terminate by PID - Close a specific process by PID."
  echo "[6] Lower priority - Reduce CPU priority of a process."
  echo "[Q] Quit - Exit Automaton Suite."
}

main() {
  print_menu
  while true; do
    read -r -p $'\nSelect option: ' choice
    case "${choice^^}" in
      1) snapshot ;;
      2) clean_temp ;;
      3) close_idle_apps ;;
      4) launch_app ;;
      5) kill_by_pid ;;
      6) lower_priority ;;
      Q|QUIT|EXIT) echo "Stay optimized. ✨"; break ;;
      *) echo "Unknown choice. Try again." ;;
    esac
  done
}

main
