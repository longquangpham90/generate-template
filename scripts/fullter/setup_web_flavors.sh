#!/bin/bash

# =====================================================
# Flutter Web + Desktop Flavor Manager
# =====================================================

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/.flutter_backup_web_desktop"

FLAVORS=("dev" "stg" "prod")

mkdir -p "$BACKUP_DIR"

# -----------------------------------------------------
# CHECK FLUTTER
# -----------------------------------------------------
if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ flutter not found in PATH"
  exit 1
fi

# -----------------------------------------------------
# UTILS
# -----------------------------------------------------
timestamp() { date +%s; }

pause() {
  read -r -p "Press Enter to continue..."
}

# -----------------------------------------------------
# BACKUP
# -----------------------------------------------------
backup_all() {
  TS=$(timestamp)
  DEST="$BACKUP_DIR/backup.$TS"

  mkdir -p "$DEST"

  echo ""
  echo "📦 Creating backup..."

  [ -f "$ROOT_DIR/pubspec.lock" ] && cp "$ROOT_DIR/pubspec.lock" "$DEST/"
  for d in web macos windows linux; do
    [ -d "$ROOT_DIR/$d" ] && cp -R "$ROOT_DIR/$d" "$DEST/"
  done

  echo "✅ Backup created at:"
  echo "👉 $DEST"
}

# -----------------------------------------------------
# RESTORE
# -----------------------------------------------------
latest_backup() {
  ls -td "$BACKUP_DIR"/backup.* 2>/dev/null | head -1
}

restore_all() {
  echo ""
  echo "♻️ Restoring last backup..."

  LAST=$(latest_backup)

  if [ -z "$LAST" ]; then
    echo "❌ No backup found"
    pause
    return
  fi

  echo "👉 Using $LAST"

  [ -f "$LAST/pubspec.lock" ] && cp "$LAST/pubspec.lock" "$ROOT_DIR/"

  for d in web macos windows linux; do
    if [ -d "$LAST/$d" ]; then
      rm -rf "$ROOT_DIR/$d"
      cp -R "$LAST/$d" "$ROOT_DIR/$d"
    fi
  done

  echo "✅ RESTORE DONE"
}

# -----------------------------------------------------
# SELECT FLAVOR
# -----------------------------------------------------
select_flavor() {
  echo ""
  echo "Select flavor:"
  select f in "${FLAVORS[@]}"; do
    if [ -n "$f" ]; then
      FLAVOR="$f"
      break
    fi
  done
}

# -----------------------------------------------------
# RUN MENU
# -----------------------------------------------------
run_menu() {
  echo ""
  echo "RUN PLATFORM:"
  echo "1) Web (Chrome)"
  echo "2) macOS"
  echo "3) Windows"
  echo "4) Linux"
  echo ""

  read -r -p "Choose: " OPT

  case "$OPT" in
    1) flutter run -d chrome --dart-define=FLAVOR=$FLAVOR ;;
    2) flutter run -d macos --dart-define=FLAVOR=$FLAVOR ;;
    3) flutter run -d windows --dart-define=FLAVOR=$FLAVOR ;;
    4) flutter run -d linux --dart-define=FLAVOR=$FLAVOR ;;
    *) echo "❌ Invalid option" ;;
  esac

  pause
}

# -----------------------------------------------------
# BUILD MENU
# -----------------------------------------------------
build_menu() {
  echo ""
  echo "BUILD PLATFORM:"
  echo "1) Web"
  echo "2) macOS"
  echo "3) Windows"
  echo "4) Linux"
  echo ""

  read -r -p "Choose: " OPT

  case "$OPT" in
    1) flutter build web --dart-define=FLAVOR=$FLAVOR ;;
    2) flutter build macos --dart-define=FLAVOR=$FLAVOR ;;
    3) flutter build windows --dart-define=FLAVOR=$FLAVOR ;;
    4) flutter build linux --dart-define=FLAVOR=$FLAVOR ;;
    *) echo "❌ Invalid option" ;;
  esac

  pause
}

# -----------------------------------------------------
# MAIN MENU
# -----------------------------------------------------
while true; do
  clear
  echo "================================="
  echo " Flutter Web + Desktop Manager"
  echo "================================="
  echo "1) Backup project"
  echo "2) Restore last backup"
  echo "3) Run"
  echo "4) Build"
  echo "5) Flutter clean"
  echo "0) Exit"
  echo ""

  read -r -p "Select option: " CHOICE

  case "$CHOICE" in
    1)
      backup_all
      pause
      ;;
    2)
      restore_all
      pause
      ;;
    3)
      select_flavor
      run_menu
      ;;
    4)
      select_flavor
      build_menu
      ;;
    5)
      flutter clean
      pause
      ;;
    0)
      echo "Bye 👋"
      exit 0
      ;;
    *)
      echo "❌ Invalid option"
      pause
      ;;
  esac
done
