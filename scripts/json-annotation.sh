#!/bin/bash

usage() {
  echo "Usage: $0 <file_or_folder> [-r|-a|-ra]"
  echo "  <file_or_folder>  : Path to the file or folder to process"
  echo "  -r                : Remove all @SerializedName and the import"
  echo "  -a                : Add @SerializedName and the import if missing"
  echo "  -ra               : Remove all @SerializedName and the import, then add back @SerializedName"
  exit 1
}

remove_serializedname() {
  echo "Removing all @SerializedName and import from file/folder: $1"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -E -i '' 's/@SerializedName\([^)]*\)[[:space:]]*,?[[:space:]]*//g' "$1"
    sed -E -i '' '/import com\.google\.gson\.annotations\.SerializedName/d' "$1"
  else
    sed -E -i 's/@SerializedName\([^)]*\)[[:space:]]*,?[[:space:]]*//g' "$1"
    sed -E -i '/import com\.google\.gson\.annotations\.SerializedName/d' "$1"
  fi

  echo "Finished removing @SerializedName and import."
}

add_serializedname() {
  echo "Adding @SerializedName to all 'val' properties in file/folder: $1"

  # Check if the import already exists
  if ! grep -q 'import com\.google\.gson\.annotations\.SerializedName' "$1"; then
    echo "Import not found, adding it..."
    if grep -q '^package ' "$1"; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -E -i '' '/^package /a\
import com.google.gson.annotations.SerializedName
' "$1"
      else
        sed -E -i '/^package /a import com.google.gson.annotations.SerializedName' "$1"
      fi
    else
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -E -i '' '1i\
import com.google.gson.annotations.SerializedName
' "$1"
      else
        sed -E -i '1i import com.google.gson.annotations.SerializedName' "$1"
      fi
    fi
  else
    echo "Import already exists, skipping."
  fi

  # Add @SerializedName above each 'val'
  tmpfile=$(mktemp)
  while IFS= read -r line
  do
    if [[ "$line" =~ ^[[:space:]]*val[[:space:]]+([a-zA-Z0-9_]+): ]]; then
      varname="${BASH_REMATCH[1]}"
      echo "    @SerializedName(\"$varname\")" >> "$tmpfile"
      echo "$line" >> "$tmpfile"
    else
      echo "$line" >> "$tmpfile"
    fi
  done < "$1"

  mv "$tmpfile" "$1"

  echo "Finished adding @SerializedName and import."
}

reset_and_add_serializedname() {
  echo "Removing all @SerializedName and import, then adding @SerializedName back in file/folder: $1"

  # Remove all @SerializedName and import
  remove_serializedname "$1"

  # Add @SerializedName back
  add_serializedname "$1"
}

auto_format() {
  echo "Automatically formatting Kotlin file using ktlint in file/folder: $1"

  # Check if ktlint is installed
  if ! command -v ktlint &> /dev/null; then
    echo "ktlint not found, please install it first."
    exit 1
  fi

  # Run ktlint to check and format the file/folder
  ktlint --format "$1"
  echo "Finished formatting with ktlint."
}

process_files() {
  # Check if path is a file or directory
  if [[ -d "$1" ]]; then
    for file in "$1"/*.kt; do
      process_file "$file" "$2"
    done
  elif [[ -f "$1" ]]; then
    process_file "$1" "$2"
  else
    echo "Invalid file or folder: $1"
    exit 1
  fi
}

process_file() {
  file="$1"
  option="$2"

  case "$option" in
    -r)
      remove_serializedname "$file"
      auto_format "$file"
      ;;
    -a)
      add_serializedname "$file"
      auto_format "$file"
      ;;
    -ra)
      reset_and_add_serializedname "$file"
      auto_format "$file"
      ;;
    *)
      usage
      ;;
  esac
}

# Main
if [[ $# -ne 2 ]]; then
  usage
fi

path="$1"
option="$2"

process_files "$path" "$option"
