#!/bin/sh
# Run this in any folder to clean ButterKnife usage (folder-scoped)

echo "🔍 Removing ButterKnife imports & annotations..."

# Backup files before modifying
echo "📦 Creating backups..."
find . -type f \( -name "*.java" -o -name "*.kt" \) ! -path "*/build/*" ! -path "*/.gradle/*" ! -path "*/generated/*" \
  -exec cp {} {}.bak \;

# Remove imports
echo "🧹 Cleaning imports..."
find . -type f \( -name "*.java" -o -name "*.kt" \) ! -path "*/build/*" ! -path "*/.gradle/*" ! -path "*/generated/*" \
  -exec sed -i '' \
    -e 's/import butterknife\..*;//g' \
    -e 's/import kotlinx\.android\.synthetic\..*;//g' \
  {} \; -print

# Remove annotations and binding calls
echo "🧽 Cleaning annotations & bind calls..."
find . -type f \( -name "*.java" -o -name "*.kt" \) ! -path "*/build/*" ! -path "*/.gradle/*" ! -path "*/generated/*" \
  -exec sed -i '' \
    -e 's/@BindView([^)]*)//g' \
    -e 's/@OnClick([^)]*)//g' \
    -e 's/@BindViews([^)]*)//g' \
    -e 's/ButterKnife\.bind([^;]*);//g' \
    -e 's/ButterKnife\.unbind([^;]*);//g' \
  {} \; -print

echo "✅ Done!"
echo "🧾 Modified files are listed above. Backups saved as *.bak"
echo "♻️ Next: remove ButterKnife dependencies in build.gradle and rebuild the project."
