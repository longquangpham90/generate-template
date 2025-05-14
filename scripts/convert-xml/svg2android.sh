#!/bin/bash

ROOT_DIR="${OVERRIDE_CURRENT_DIR:-$(pwd -P)}"
echo "📂 Currently at: $ROOT_DIR"

# Check input folder argument
if [ -z "$1" ]; then
    echo "❗ Usage: ./convertSVGFolderFast.sh <input_svg_folder>"
    exit 1
fi

INPUT_DIR="$1"
ROOT_PROJECT=$(git rev-parse --show-toplevel)
JAR_FILE="/${ROOT_PROJECT}/tools/scripts/convert-xml/svg2android.jar"

echo "=== file://$JAR_FILE"
# Check if the input folder exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Input folder does not exist: $INPUT_DIR"
    exit 1
fi
#
# Check if svg2android.jar file exists
if [ ! -f "$JAR_FILE" ]; then
    echo "❌ svg2android.jar file not found."
    exit 1
fi

# Create ProcessedSVG folder if it does not exist
mkdir -p "$INPUT_DIR/ProcessedSVG"

# Convert all SVG files in the input folder
echo "🚀 Converting SVG folder from $INPUT_DIR..."
echo "👉 Running: java -jar \"$JAR_FILE\" \"$INPUT_DIR\""
java -jar "$JAR_FILE" "$INPUT_DIR"

# Move and rename XML files in ProcessedSVG
for file in "$INPUT_DIR/ProcessedSVG"/*.xml; do
    if [ -f "$file" ]; then
        filename="${file##*/}"
        mv "$file" "$ROOT_DIR/${filename/ic_ic_/ic_}"
        echo "🔄 Moved & renamed: file://$ROOT_DIR/${filename/ic_ic_/ic_}"
    fi
done

# Remove ProcessedSVG folder
rm -rf "$INPUT_DIR/ProcessedSVG"

echo "✅ Conversion complete, checked prefix and moved files to file://$ROOT_DIR"
