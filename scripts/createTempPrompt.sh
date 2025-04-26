#!/bin/bash
chmod +x "$(realpath "$0")"

if [ -z "$NAME" ]; then
  read -p "🔤 Name Component (Exp: Profile): " NAME
fi

if [ -z "$TYPE" ]; then
  read -p "📦 Type (Fragment / Activity / DialogFragment / BottomSheet): " TYPE
fi


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/createTemp.sh" "$NAME" "$TYPE"
