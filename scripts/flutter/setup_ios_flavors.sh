#!/bin/bash
set -e

# =====================================================
# iOS Flavor + LLDB Manager (Flutter)
# =====================================================

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$ROOT_DIR/ios"
PROJ="$IOS_DIR/Runner.xcodeproj"
PBXPROJ="$PROJ/project.pbxproj"
SCHEME_DIR="$PROJ/xcshareddata/xcschemes"

FLAVORS=("dev" "stg" "prod")
BASES=("Debug" "Release" "Profile")

LLDB_PATH='$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit'

timestamp() { date +%s; }

latest_backup() {
  ls -t "$1".backup.* 2>/dev/null | head -1
}

has_cfg() { grep -q "$1;" "$PBXPROJ"; }

# =====================================================
# BACKUP
# =====================================================
backup_all() {
  TS=$(timestamp)

  cp "$PBXPROJ" "$PBXPROJ.backup.$TS"

  if [ -d "$SCHEME_DIR" ]; then
    cp -R "$SCHEME_DIR" "$SCHEME_DIR.backup.$TS"
  fi

  echo ""
  echo "📦 Backup created:"
  echo " - $PBXPROJ.backup.$TS"
  echo " - $SCHEME_DIR.backup.$TS"
}

# =====================================================
# RESTORE
# =====================================================
restore_all() {
  echo ""
  echo "♻️ Restoring last backup..."

  LAST_PBX=$(latest_backup "$PBXPROJ")

  if [ -z "$LAST_PBX" ]; then
    echo "❌ No pbxproj backup found"
    return
  fi

  cp "$LAST_PBX" "$PBXPROJ"

  LAST_SCHEME=$(latest_backup "$SCHEME_DIR")

  if [ -n "$LAST_SCHEME" ]; then
    rm -rf "$SCHEME_DIR"
    cp -R "$LAST_SCHEME" "$SCHEME_DIR"
  fi

  echo "✅ RESTORE DONE — reopen Xcode"
}

# =====================================================
# FIX
# =====================================================
fix_all() {
  echo ""
  echo "🚀 Running AUTO FIX..."

  backup_all

  # restore base configs
  for base in "${BASES[@]}"; do
    if ! has_cfg "$base"; then
      FL=$(grep -o "${base}-[a-zA-Z0-9_]*;" "$PBXPROJ" | head -1 | sed 's/;//')
      if [ -n "$FL" ]; then
        echo "➕ Restoring $base from $FL"
        sed -i '' "s/$FL;/$FL;\n\t\t\t\t$base;/g" "$PBXPROJ"
      fi
    fi
  done

  # create flavored configs
  for flavor in "${FLAVORS[@]}"; do
    for base in "${BASES[@]}"; do
      NAME="$base-$flavor"
      if has_cfg "$NAME"; then
        echo "✔️ $NAME exists"
      elif has_cfg "$base"; then
        echo "➕ Creating $NAME from $base"
        sed -i '' "s/$base;/$base;\n\t\t\t\t$NAME;/g" "$PBXPROJ"
      fi
    done
  done

  # patch LLDB in schemes
  echo ""
  echo "🛠 Updating LLDB init in schemes..."

  for flavor in "${FLAVORS[@]}"; do
    FILE="$SCHEME_DIR/$flavor.xcscheme"
    [ -f "$FILE" ] || continue

    if ! grep -q flutter_lldbinit "$FILE"; then
      sed -i '' \
        "s#<LaunchAction #<LaunchAction customLLDBInitFile=\"YES\" lldbInitFile=\"$LLDB_PATH\" #g" \
        "$FILE"

      sed -i '' \
        "s#<TestAction #<TestAction customLLDBInitFile=\"YES\" lldbInitFile=\"$LLDB_PATH\" #g" \
        "$FILE"

      echo "✔️ Patched $flavor"
    else
      echo "✔️ $flavor already configured"
    fi
  done

  echo ""
  echo "✅ FIX COMPLETE"
  echo "👉 Run:"
  echo "flutter clean"
  echo "flutter run --flavor dev"
}

# =====================================================
# MENU
# =====================================================
while true; do
  echo ""
  echo "==============================="
  echo " iOS Flavor Manager"
  echo "==============================="
  echo "1) Fix iOS flavors + LLDB (backup first)"
  echo "2) Restore from last backup"
  echo "3) Exit"
  echo ""

  read -r -p "Select option: " CHOICE

  case "$CHOICE" in
    1)
      fix_all
      ;;
    2)
      restore_all
      ;;
    3)
      echo "Bye 👋"
      exit 0
      ;;
    *)
      echo "❌ Invalid option"
      ;;
  esac
done
