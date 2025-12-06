#!/bin/bash

# ===== INIT =====
ROOT_DIR="${OVERRIDE_CURRENT_DIR:-$(pwd -P)}"
echo "📂 Currently at: $ROOT_DIR"

# ===== INPUT FOLDER =====
read -p "📁 Input path folder SVG: " INPUT_DIR
if [ -z "$INPUT_DIR" ]; then
    echo "❌ Folder NOT empty!"
    exit 1
fi
INPUT_DIR="$(realpath "$INPUT_DIR")"

# ===== INPUT PREFIX =====
read -p "🔤 Input PREFIX (ex: ic_): " PREFIX
if [ -z "$PREFIX" ]; then
    echo "❌ Prefix NOT empty!"
    exit 1
fi

# ===== ROOT PROJECT & JAR =====
ROOT_PROJECT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")
JAR_FILE="${ROOT_PROJECT}/tools/scripts/convert-xml/svgToAndroid-1.0.0.jar"

echo "=== Using JAR: file://$JAR_FILE"

# ===== CHECK FOLDER & JAR =====
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Input folder NOT exist: $INPUT_DIR"
    exit 1
fi

if [ ! -f "$JAR_FILE" ]; then
    echo "❌ svgToAndroid-1.0.0.jar file not found: $JAR_FILE"
    exit 1
fi

# ===== CREATE PROCESSED FOLDER =====
PROCESSED_DIR="$INPUT_DIR/ProcessedSVG"
mkdir -p "$PROCESSED_DIR"

# ===== RUN CONVERTER =====
echo "🚀 Converting SVG folder from: $INPUT_DIR"
echo "👉 Running: java -jar \"$JAR_FILE\" \"$INPUT_DIR\""
java -jar "$JAR_FILE" "$INPUT_DIR"

# ===== MOVE & RENAME =====
echo "🔧 Moving & renaming XML files..."
PREFIX="$(echo "$PREFIX" | xargs)"
PREFIX="$(echo "$PREFIX" | tr '[:upper:]' '[:lower:]')"
PREFIX="${PREFIX//[^a-z0-9_]/_}"

for file in "$INPUT_DIR/ProcessedSVG"/*.xml; do
    [ ! -f "$file" ] && continue
    filename="${file##*/}"
    basename="${filename%.xml}"
    safeBasename="$(echo "$basename" | tr '[:upper:]' '[:lower:]')"
    safeBasename="${safeBasename//[^a-z0-9_]/_}"
    newName="${PREFIX}${safeBasename}.xml"
    echo "DEBUG: Moving '$filename' -> '$newName'"
    mv "$file" "$ROOT_DIR/$newName"
done

# ===== CLEANUP =====
rm -rf "$PROCESSED_DIR"

echo "✅ Conversion complete. All files moved to: file://$ROOT_DIR"
