#!/bin/bash
chmod +x "$(realpath "$0")"
# Check install envsubst ready
if ! command -v envsubst >/dev/null 2>&1; then
  echo "⚠️  envsubst NOT install, installing..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew not installed. Please install it first:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
  brew install gettext
  brew link --force gettext
else
  echo "✅ envsubst installed"
fi

# Function to convert CamelCase to snake_case
camel_to_snake() {
  echo "$1" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]'
}

# Map TYPE -> class suffix (e.g., Fragment -> Fragment)
map_type_to_class() {
  case "$1" in
    Fragment)
      echo "Fragment"
      ;;
    Activity)
      echo "Activity"
      ;;
    DialogFragment)
      echo "DialogFragment"
      ;;
    BottomSheet)
      echo "DialogFragment"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Map TYPE -> snake_case prefix (e.g., DialogFragment -> dialog_fragment)
map_type_to_lower() {
  case "$1" in
    Fragment)
      echo "fragment"
      ;;
    Activity)
      echo "activity"
      ;;
    DialogFragment)
      echo "dialog_fragment"
      ;;
    BottomSheet)
      echo "dialog_fragment"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}


NAME=$1

if [ -z "$NAME" ]; then
  echo "❌ Please provide a Component name (e.g., ./createTemp.sh Profile fragment)"
  exit 1
fi

TYPE=$2

# List of valid TYPEs
VALID_TYPES=("Fragment" "Activity" "DialogFragment" "BottomSheet")

if [ -z "$TYPE" ]; then
  echo "ℹ️  No TYPE provided. Defaulting to: Fragment"
  TYPE="Fragment"
else
  if [[ ! " ${VALID_TYPES[@]} " =~ " ${TYPE} " ]]; then
    echo "❌ Invalid TYPE: $TYPE"
    echo "✅ Valid TYPEs: ${VALID_TYPES[*]}"
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="${OVERRIDE_CURRENT_DIR:-$(pwd -P)}"

if [[ "$CURRENT_DIR" =~ /src/main/(java|kotlin)/ ]]; then
  SOURCE_TYPE=$(echo "$CURRENT_DIR" | grep -oE 'src/main/(java|kotlin)' | cut -d'/' -f3)
  PACKAGE_PATH="${CURRENT_DIR##*src/main/$SOURCE_TYPE/}"
  PACKAGE_NAME="${PACKAGE_PATH//\//.}"
  MODULE_PATH="${CURRENT_DIR%%/src/main/$SOURCE_TYPE/*}"
else
  echo "❌ Cannot find /src/main/java/ or /src/main/kotlin/ in the current path. $CURRENT_DIR"
  exit 1
fi

# Assign file paths
EXT_FILE=$(map_type_to_class "$TYPE")
KT_FILE="${CURRENT_DIR}/${NAME}${EXT_FILE}.kt"
VKT_FILE="${CURRENT_DIR}/${NAME}ViewModel.kt"
DIR_XML="${MODULE_PATH}/src/main/res/layout"
lower_type_camel_to_snake=$(map_type_to_lower "$TYPE")
lower_name=$(camel_to_snake "$NAME")
XML_FILE="${DIR_XML}/${lower_type_camel_to_snake}_${lower_name}.xml"
SOURCE_TYPE=$(echo "$KT_FILE" | grep -oE 'src/main/(java|kotlin)' | tail -n1 | cut -d'/' -f3)
PACKAGE_PATH=$(echo "$KT_FILE" | sed -n "s|.*/src/main/$SOURCE_TYPE/\(.*\)/${NAME}${EXT_FILE}.kt|\1|p")
PACKAGE_NAME=$(echo "$PACKAGE_PATH" | tr '/' '.')

# Prefer to get applicationId from build.gradle
if [[ -f "$MODULE_PATH/build.gradle" ]]; then
  applicationId=$(grep -oP 'applicationId\s+"\K[^"]+' "$MODULE_PATH/build.gradle" 2>/dev/null)
fi

# If not found, guess from package name
if [[ -z "$applicationId" ]]; then
  IFS='.' read -ra segments <<< "$PACKAGE_NAME"
  if (( ${#segments[@]} >= 3 )); then
    applicationId="${segments[0]}.${segments[1]}.${segments[2]}"
  else
    applicationId="$PACKAGE_NAME"
  fi
fi

# Create folders if needed
mkdir -p "$CURRENT_DIR"
mkdir -p "$DIR_XML"

# Read template content from /template/{type}/
ROOT_PROJECT=$(git rev-parse --show-toplevel)
RELATIVE_PATH=${KT_FILE#$ROOT_PROJECT/}
moduleName=$(echo "$RELATIVE_PATH" | cut -d'/' -f1)

case "$moduleName" in
  "features")
    TEMPLATE_DIR="${ROOT_PROJECT}/tools/template/${lower_type_camel_to_snake}"
    ;;
  *)
    TEMPLATE_DIR="${ROOT_PROJECT}/${moduleName}/tools/template/${lower_type_camel_to_snake}"
    ;;
esac

FRAGMENT_TEMPLATE="${TEMPLATE_DIR}/${lower_type_camel_to_snake}_template.kt"
VIEWMODEL_TEMPLATE="${TEMPLATE_DIR}/view_model_template.kt"
XML_TEMPLATE="${TEMPLATE_DIR}/${lower_type_camel_to_snake}_template.xml"

if [[ -f "$FRAGMENT_TEMPLATE" ]]; then
  FRAGMENT_CONTENT=$(cat "$FRAGMENT_TEMPLATE")
else
  FRAGMENT_TEMPLATE_PATH="file://$FRAGMENT_TEMPLATE"
  echo "❌ Template file not found: $FRAGMENT_TEMPLATE_PATH"
  exit 1
fi

if [[ -f "$VIEWMODEL_TEMPLATE" ]]; then
  VIEWMODEL_CONTENT=$(cat "$VIEWMODEL_TEMPLATE")
else
  VIEWMODEL_TEMPLATE_PATH="file://$VIEWMODEL_TEMPLATE"
  echo "❌ Template file not found: $VIEWMODEL_TEMPLATE_PATH"
  exit 1
fi

if [[ -f "$XML_TEMPLATE" ]]; then
  XML_CONTENT=$(cat "$XML_TEMPLATE")
else
  XML_TEMPLATE_PATH="file://$XML_TEMPLATE"
  echo "❌ Template file not found: $XML_TEMPLATE_PATH"
  exit 1
fi

# Export for envsubst usage
export applicationId NAME PACKAGE_NAME lower_name

# Write files using envsubst
echo "$FRAGMENT_CONTENT" | envsubst > "$KT_FILE"
echo "$VIEWMODEL_CONTENT" | envsubst > "$VKT_FILE"
echo "$XML_CONTENT" | envsubst > "$XML_FILE"

KT_FILE_PATH="file://$KT_FILE"
VKT_FILE_PATH="file://$VKT_FILE"
XML_FILE_PATH="file://$XML_FILE"

echo "✅ Created template files successfully:"
echo -e "🔗 Kotlin:    $KT_FILE_PATH"
echo -e "🔗 ViewModel: $VKT_FILE_PATH"
echo -e "🔗 XML:       $XML_FILE_PATH"