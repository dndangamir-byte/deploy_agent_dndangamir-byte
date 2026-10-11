#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"
PROJECT=""

cleanup() {
  echo ""
  echo "Deployment interrupted! Archiving incomplete project..."
  if [ -n "$PROJECT" ] && [ -d "$PROJECT" ]; then
    zip -r "${PROJECT}_archive.zip" "$PROJECT" > /dev/null
    echo "Archive created: ${PROJECT}_archive.zip"
    rm -rf "$PROJECT"
  fi
  echo "Session closed cleanly."
  exit 1
}

deploy() {
  for cmd in python3 zip; do
    if ! command -v $cmd > /dev/null 2>&1; then
      echo "ERROR: $cmd is not installed. Install it and try again."
      return 1
    fi
  done
  echo "Pre-flight OK: python3 and zip found."

  read -p "Enter directory name: " name
  if [ -z "$name" ]; then echo "ERROR: name cannot be empty."; return 1; fi
  PROJECT="attendance_tracker_$name"
  if [ -d "$PROJECT" ]; then
    read -p "$PROJECT already exists. Overwrite? (y/n): " ow
    if [ "$ow" != "y" ]; then echo "Aborted."; PROJECT=""; return 1; fi
    rm -rf "$PROJECT"
  fi

  trap cleanup SIGINT SIGTSTP
  mkdir -p "$PROJECT/Helpers" "$PROJECT/reports"

  cp "$TEMPLATES/attendance_checker.py" "$PROJECT/"
  cp "$TEMPLATES/config.json" "$PROJECT/Helpers/"
  echo "Roster: A) copy from template  B) generate fresh"
  read -p "Choose A or B: " opt
  if [ "$opt" = "A" ] || [ "$opt" = "a" ]; then
    while true; do
      read -p "How many students to copy? " n
      [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt 0 ] && break
      echo "Please enter a positive number."
    done
    head -n $((n+1)) "$TEMPLATES/assets.csv" > "$PROJECT/Helpers/assets.csv"
    sed -i 's/"total_sessions": [0-9]/"total_sessions": 5/' "$PROJECT/Helpers/config.json"
  else
    while true; do
      read -p "How many students? " n
      [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt 0 ] && break
      echo "Please enter a positive number."
    done
    names=("Alice Johnson" "Bob Smith" "Carol White" "David Brown" "Eve Davis" "Frank Miller" "Grace Lee" "Henry Wilson" "Ivy Moore" "Jack Taylor")
    emails=(alice bob carol david eve frank grace henry ivy jack)
    echo "Email,Names,Attendance Count,Absence Count" > "$PROJECT/Helpers/assets.csv"
    for ((i=0; i<n; i++)); do
      idx=$((i%10)); suffix=""
      [ $i -ge 10 ] && suffix=$((i/10))
      echo "${emails[$idx]}${suffix}@example.com,${names[$idx]},0,0" >> "$PROJECT/Helpers/assets.csv"
    done
    sed -i 's/"total_sessions": [0-9]/"total_sessions": 1/' "$PROJECT/Helpers/config.json"
  fi

  chmod +x "$PROJECT/attendance_checker.py"
  chmod 600 "$PROJECT/Helpers/config.json"
  echo "Permissions set: attendance_checker.py = +x, Helpers/config.json = 600"

  read -p "Update attendance thresholds? (y/n): " up
  if [ "$up" = "y" ]; then
    read -p "Warning threshold (default 75): " w
    read -p "Failure threshold (default 50): " f
    if [[ "$w" =~ ^[0-9]+$ ]] && [[ "$f" =~ ^[0-9]+$ ]]; then
      sed -i "s/\"warning\": [0-9]/\"warning\": $w/" "$PROJECT/Helpers/config.json"
      sed -i "s/\"failure\": [0-9]/\"failure\": $f/" "$PROJECT/Helpers/config.json"
      echo "Thresholds updated: warning=$w failure=$f"
    else
      echo "Invalid numbers. Keeping defaults."
    fi
  fi

  trap - SIGINT SIGTSTP
  echo "Deployment complete. Verifying by running the app..."
  (cd "$PROJECT" && python3 attendance_checker.py)
}

run_app() {
  read -p "Enter directory name: " name
  PROJECT="attendance_tracker_$name"
  if [ ! -d "$PROJECT" ]; then echo "ERROR: $PROJECT not found."; PROJECT=""; return 1; fi
  (cd "$PROJECT" && python3 attendance_checker.py)
}

archive_logs() {
  read -p "Enter directory name: " name
  PROJECT="attendance_tracker_$name"
  if [ ! -d "$PROJECT" ]; then echo "ERROR: $PROJECT not found."; PROJECT=""; return 1; fi
  ts=$(date +%Y%m%d_%H%M%S)
  for log in attendance absent; do
    src="$PROJECT/reports/$log.log"
    if [ -f "$src" ]; then
      mkdir -p "$PROJECT/archives/$log"
      mv "$src" "$PROJECT/archives/$log/${log}_${ts}.log"
      echo "Archived: $PROJECT/archives/$log/${log}_${ts}.log"
    else
      echo "Skipped: $log.log does not exist."
    fi
  done
}

while true; do
  echo ""
  echo "===== Deploy Agent ====="
  echo "1) Deploy  2) Run  3) Archive logs  4) Exit"
  read -p "Choose: " c
  case $c in
    1) deploy ;;
    2) run_app ;;
    3) archive_logs ;;
    4) echo "Bye."; exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
