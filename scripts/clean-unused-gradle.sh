#!/bin/bash
chmod +x "$(realpath "$0")"

# Find the project root directory containing gradle-wrapper.properties
find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/gradle/wrapper/gradle-wrapper.properties" ]]; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
  echo "❌ gradle-wrapper.properties not found!" >&2
  exit 1
}

# Get the project root
project_root=$(find_project_root)

# Extract current Gradle version
gradle_version=$(grep distributionUrl "$project_root/gradle/wrapper/gradle-wrapper.properties" | sed -E 's/.*gradle-([0-9.]+)-bin.zip/\1/')

if [ -z "$gradle_version" ]; then
  echo "❌ Could not find Gradle version!"
  exit 1
fi

echo "👉 Current Gradle version to keep: $gradle_version"

# Function to clean unused Gradle build cache folders like .gradle/8.13/
clean_gradle_caches() {
  local target_dir="$1"

  if [[ ! -d "$target_dir" ]]; then
    echo "❌ Directory $target_dir does not exist!"
    return
  fi

  echo "🔍 Scanning $target_dir for versioned cache folders..."
  find "$target_dir" -maxdepth 1 -type d | grep -E "/[0-9]+\.[0-9]+(\.[0-9]+)?$" | while read -r version_dir; do
    version_name=$(basename "$version_dir")
    echo ">>> Checking $version_dir"
    if [[ "$version_name" != "$gradle_version" ]]; then
      echo "🗑 Deleting $version_dir"
      rm -rf "$version_dir"
      if [ $? -eq 0 ]; then
        echo "✅ Successfully deleted $version_dir"
      else
        echo "❌ Failed to delete $version_dir"
      fi
    else
      echo "✅ Keeping $version_dir"
    fi
  done
}

# Scan all .gradle folders inside the project
find "$project_root" -type d -name ".gradle" | while read -r gradle_hidden_dir; do
  clean_gradle_caches "$gradle_hidden_dir"
done

echo "🎯 Full project-only Gradle cleanup completed!"
