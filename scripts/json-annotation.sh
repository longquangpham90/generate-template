#!/bin/bash

usage() {
  echo "Usage: $0 <file_or_folder> [-r|-a|-ra]"
  echo "  <file_or_folder>  : Path to the file or folder to process"
  echo "  -r                : Remove all @SerializedName and the import"
  echo "  -a                : Add @SerializedName and the import if missing"
  echo "  -ra               : Remove all @SerializedName and the import, then add back @SerializedName"
  exit 1
}

removeSerializedName() {
  echo "Removing all @SerializedName and import from file/folder: $1"
  ext="${1##*.}"
  if [[ "$ext" != "kt" && "$ext" != "java" ]]; then
    echo "Skipped (unsupported file extension: .$ext): $1"
    return
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -E -i '' 's/@(field:)?SerializedName\([^)]*\)[[:space:]]*(,)?[[:space:]]*//g' "$1"
    sed -E -i '' '/^\s*import\s+com\.google\.gson\.annotations\.SerializedName\s*;/d' "$1"
    sed -E -i '' '/^\s*import\s+com\.google\.gson\.annotations\.SerializedName\s*$/d' "$1"
  else
    sed -E -i 's/@(field:)?SerializedName\([^)]*\)[[:space:]]*(,)?[[:space:]]*//g' "$1"
    sed -E -i '/^\s*import\s+com\.google\.gson\.annotations\.SerializedName\s*;/d' "$1"
    sed -E -i '/^\s*import\s+com\.google\.gson\.annotations\.SerializedName\s*$/d' "$1"
  fi

  echo "Finished removing @SerializedName and import from: $1"
}
addSerializedName() {
  file="$1"

  echo "Adding @SerializedName to file: $file"

  # Determine extension
  extension="${file##*.}"

  # Check for unsupported file types first
  if [[ "$extension" != "kt" && "$extension" != "java" ]]; then
    echo "Unsupported file type: $extension"
    return
  fi

  # Prefer processing Java files first
  if [[ "$extension" == "java" ]]; then
    # Java file: Always add import with semicolon if missing
    echo "Adding import for SerializedName..."
    if ! grep -q 'import com\.google\.gson\.annotations\.SerializedName' "$file"; then
      if grep -q '^package ' "$file"; then
        # Add import after package declaration
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '/^package /a\
import com.google.gson.annotations.SerializedName;
' "$file"
        else
          sed -E -i '/^package /a import com.google.gson.annotations.SerializedName;' "$file"
        fi
      else
        # Add import at the beginning (if no package statement is found)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '1i\
import com.google.gson.annotations.SerializedName;
' "$file"
        else
          sed -E -i '1i import com.google.gson.annotations.SerializedName;' "$file"
        fi
      fi
    else
      echo "Import already exists, skipping."
    fi

    # Process Java file lines
    tmpfile=$(mktemp)
    while IFS= read -r line; do
      # Improved regex to capture public, private, protected modifiers, with complex types
      if [[ "$line" =~ ^[[:space:]]*(private|public|protected)[[:space:]]+([a-zA-Z0-9_<>?,\[\]]+)[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]*[\;] ]]; then
        varname="${BASH_REMATCH[3]}"  # Capture the variable name
        echo "    @SerializedName(\"$varname\")" >> "$tmpfile"
        echo "$line" >> "$tmpfile"
      else
        echo "$line" >> "$tmpfile"
      fi
    done < "$file"

    mv "$tmpfile" "$file"
    echo "Finished adding @SerializedName for Java file."

  elif [[ "$extension" == "kt" ]]; then
    # Kotlin file: Add import without semicolon if missing
    echo "Adding import for SerializedName..."
    if ! grep -q 'import com\.google\.gson\.annotations\.SerializedName' "$file"; then
      if grep -q '^package ' "$file"; then
        # Add import after package declaration (Kotlin)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '/^package /a\
import com.google.gson.annotations.SerializedName
' "$file"
        else
          sed -E -i '/^package /a import com.google.gson.annotations.SerializedName' "$file"
        fi
      else
        # Add import at the beginning (Kotlin)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '1i\
import com.google.gson.annotations.SerializedName
' "$file"
        else
          sed -E -i '1i import com.google.gson.annotations.SerializedName' "$file"
        fi
      fi
    else
      echo "Import already exists, skipping."
    fi

    # Process Kotlin file lines
    tmpfile=$(mktemp)
    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*(val|var)[[:space:]]+([a-zA-Z0-9_]+): ]]; then
        varname="${BASH_REMATCH[2]}"
        echo "    @SerializedName(\"$varname\")" >> "$tmpfile"
        echo "$line" >> "$tmpfile"
      else
        echo "$line" >> "$tmpfile"
      fi
    done < "$file"

    mv "$tmpfile" "$file"
    echo "Finished adding @SerializedName for Kotlin file."
  fi
}

addSerializedName() {
  file="$1"

  echo "Adding @SerializedName to file: $file"

  # Determine extension
  extension="${file##*.}"

  # Check for unsupported file types first
  if [[ "$extension" != "kt" && "$extension" != "java" ]]; then
    echo "Unsupported file type: $extension"
    return
  fi

  # Prefer processing Java files first
  if [[ "$extension" == "java" ]]; then
    echo "Processing Java file: $file"
    # Java file: Always add import with semicolon if missing
    echo "Checking for import of SerializedName..."
    if ! grep -q 'import com\.google\.gson\.annotations\.SerializedName' "$file"; then
      echo "Import not found. Adding import..."
      if grep -q '^package ' "$file"; then
        # Add import after package declaration
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '/^package /a\
import com.google.gson.annotations.SerializedName;
' "$file"
        else
          sed -E -i '/^package /a import com.google.gson.annotations.SerializedName;' "$file"
        fi
      else
        # Add import at the beginning (if no package statement is found)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '1i\
import com.google.gson.annotations.SerializedName;
' "$file"
        else
          sed -E -i '1i import com.google.gson.annotations.SerializedName;' "$file"
        fi
      fi
    else
      echo "Import already exists, skipping."
    fi

    # Process Java file lines
    tmpfile=$(mktemp)
    previous_line=""
    while IFS= read -r line; do
        trimmed_current=$(echo "$line" | sed 's/^[[:space:]]*//')
        trimmed_previous=$(echo "$previous_line" | sed 's/^[[:space:]]*//')
        if [[ "$trimmed_current" == package* || "$trimmed_current" == import* ]]; then
            echo "$line" >> "$tmpfile"
            previous_line="$line"
            continue
        fi
        # Nếu current line kết thúc bằng ';' (field)
        if echo "$trimmed_current" | grep -qE ';[[:space:]]*$'; then
          # Nếu previous line KHÔNG chứa @SerializedName
          if ! echo "$trimmed_previous" | grep -qE '^\s*@SerializedName'; then
            # Lấy tên biến
            var_name=$(echo "$trimmed_current" | awk -F'[ ;=]+' '{print $(NF-1)}')
            if [[ "$var_name" != "com.google.gson.annotations.SerializedName" ]]; then
              echo "    @SerializedName(\"$var_name\")" >> "$tmpfile"
            fi
          fi
        fi

        echo "$line" >> "$tmpfile"
        previous_line="$line"
    done < "$file"
    mv "$tmpfile" "$file"
    echo "Finished adding @SerializedName for Java file."
  elif [[ "$extension" == "kt" ]]; then
    # Kotlin file: Add import without semicolon if missing
    echo "Processing Kotlin file: $file"
    if ! grep -q 'import com\.google\.gson\.annotations\.SerializedName' "$file"; then
      echo "Import not found. Adding import..."
      if grep -q '^package ' "$file"; then
        # Add import after package declaration (Kotlin)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '/^package /a\
import com.google.gson.annotations.SerializedName
' "$file"
        else
          sed -E -i '/^package /a import com.google.gson.annotations.SerializedName' "$file"
        fi
      else
        # Add import at the beginning (Kotlin)
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed -E -i '' '1i\
import com.google.gson.annotations.SerializedName
' "$file"
        else
          sed -E -i '1i import com.google.gson.annotations.SerializedName' "$file"
        fi
      fi
    else
      echo "Import already exists, skipping."
    fi

    # Process Kotlin file lines
    tmpfile=$(mktemp)
    while IFS= read -r line; do
      if [[ "$line" =~ "@SerializedName" ]]; then
        echo "$line" >> "$tmpfile"  # Skip adding annotation if already present
      elif [[ "$line" =~ ^[[:space:]]*(val|var)[[:space:]]+([a-zA-Z0-9_]+): ]]; then
        varname="${BASH_REMATCH[2]}"
        if ! grep -q "@SerializedName(\"$varname\")" "$file"; then
          echo "    @SerializedName(\"$varname\")" >> "$tmpfile"
        fi
        echo "$line" >> "$tmpfile"
      else
        echo "$line" >> "$tmpfile"
      fi
    done < "$file"

    mv "$tmpfile" "$file"
    echo "Finished adding @SerializedName for Kotlin file."
  fi
}

resetAndAddSerializedName() {
  echo "Removing all @SerializedName and import, then adding @SerializedName back in file/folder: $1"

  # Remove all @SerializedName and import
  removeSerializedName "$1"

  # Add @SerializedName back
  addSerializedName "$1"
}

autoFormat() {
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

processFiles() {
  # Check if path is a file or directory
  if [[ -d "$1" ]]; then
    find "$1" \( -name "*.kt" -o -name "*.java" \) | while read -r file; do
      processFile "$file" "$2"
    done
  elif [[ -f "$1" ]]; then
    processFile "$1" "$2"
  else
    echo "Invalid file or folder: $1"
    exit 1
  fi
}

processFile() {
  file="$1"
  option="$2"

  case "$option" in
    -r)
      removeSerializedName "$file"
      ;;
    -a)
      addSerializedName "$file"
      ;;
    -ra)
      resetAndAddSerializedName "$file"
      ;;
    *)
      usage
      ;;
  esac

  # Only auto format if file is Kotlin (.kt)
  if [[ "$file" == *.kt ]]; then
    autoFormat "$file"
  fi
}


# Main
if [[ $# -ne 2 ]]; then
  usage
fi

path="$1"
option="$2"

processFiles "$path" "$option"
