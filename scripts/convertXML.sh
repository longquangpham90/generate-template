#!/bin/bash

ROOT_DIR="${OVERRIDE_CURRENT_DIR:-$(pwd -P)}"

declare -a REPLACEMENTS=(
  "TextView|androidx.appcompat.widget.AppCompatTextView"
  "ImageView|androidx.appcompat.widget.AppCompatImageView"
  "EditText|androidx.appcompat.widget.AppCompatEditText"
  "Button|androidx.appcompat.widget.AppCompatButton"
  "CheckBox|androidx.appcompat.widget.AppCompatCheckBox"
  "RadioButton|androidx.appcompat.widget.AppCompatRadioButton"
  "AutoCompleteTextView|androidx.appcompat.widget.AppCompatAutoCompleteTextView"
  "MultiAutoCompleteTextView|androidx.appcompat.widget.AppCompatMultiAutoCompleteTextView"
  "RatingBar|androidx.appcompat.widget.AppCompatRatingBar"
  "SeekBar|androidx.appcompat.widget.AppCompatSeekBar"
  "ToggleButton|androidx.appcompat.widget.AppCompatToggleButton"
  "Spinner|androidx.appcompat.widget.AppCompatSpinner"
)

# Detect OS for sed -i compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

# Build sed replacements
SED_COMMANDS=()
for pair in "${REPLACEMENTS[@]}"; do
  IFS='|' read -r from to <<< "$pair"
  SED_COMMANDS+=("-e" "s|<$from|<$to|g" "-e" "s|</$from>|</$to>|g")
done

PATTERN=$(printf "%s\n" "${REPLACEMENTS[@]%%|*}" | paste -sd "|" -)

find "$ROOT_DIR" -type f -name "*.xml" \
  ! -path "*/build/*" ! -path "*/.idea/*" ! -path "*/.gradle/*" | while read -r file; do
  MODIFIED=false
  if grep -qE "$PATTERN" "$file"; then
    sed "${SED_INPLACE[@]}" "${SED_COMMANDS[@]}" "$file"
    MODIFIED=true
  fi
  sed -i "" '/^[ \t]\{2,\}$/d' "$file"
  awk 'NF || !blank++' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

  if $MODIFIED; then
    echo "🧹 Cleaned & updated: $file"
  fi
done
