y#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

to_file_uri () {
  local p="$1"

  case "$OSTYPE" in
    msys*|cygwin*)
      p=$(cygpath -m "$p")
      echo "file:///$p"
      ;;
    *)
      echo "file://$p"
      ;;
  esac
}

find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/pubspec.yaml" ]]; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
  echo ""
}

PROJECT_ROOT=$(find_project_root)

[ -z "$PROJECT_ROOT" ] && {
  echo "❌ Cannot find pubspec.yaml project root"
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect Windows Git Bash
case "$OSTYPE" in
  msys*|cygwin*)
    SCRIPT_DIR_WIN=$(cygpath -w "$SCRIPT_DIR")
    TMP_JSON="$SCRIPT_DIR_WIN\\.json_preview.json"
    PY_TMP_JSON="$TMP_JSON"
    ;;
  *)
    TMP_JSON="$SCRIPT_DIR/.json_preview.json"
    PY_TMP_JSON="$TMP_JSON"
    ;;
esac

echo "📋 Reading JSON from clipboard..."

if command -v pbpaste &>/dev/null; then
  pbpaste > "$TMP_JSON"
elif command -v powershell.exe &>/dev/null; then
  powershell.exe -NoProfile -Command "Get-Clipboard -Raw" > "$TMP_JSON"
elif command -v xclip &>/dev/null; then
  xclip -selection clipboard -o > "$TMP_JSON"
else
  echo "❌ Clipboard tool not found"
  exit 1
fi

[ ! -s "$TMP_JSON" ] && { echo "❌ Clipboard empty"; exit 1; }

echo "👉 JSON Preview: $(to_file_uri "$TMP_JSON")"
read -p "Press ENTER to continue..."

read -p "Base name (User, Product...): " NAME
[ -z "$NAME" ] && NAME="Demo"

SNAKE=$(echo "$NAME" | sed -E 's/([a-z])([A-Z])/\1_\2/g' | tr 'A-Z' 'a-z')

read -p "Auto path? (y/n): " AUTO

if [[ "$AUTO" =~ ^[Yy]$ ]]; then
  ENTITY_DIR="$PROJECT_ROOT/lib/data/entity"
  MODEL_DIR="$PROJECT_ROOT/lib/domain/model"
  MAPPER_DIR="$PROJECT_ROOT/lib/data/mapper"
else
  read -p "Entity folder: " ENTITY_DIR
  read -p "Model folder: " MODEL_DIR
  read -p "Mapper folder: " MAPPER_DIR
fi

safe_dir () {
  local input="$1"

  [ -z "$input" ] && { echo ""; return; }

  input="${input//\\//}"

  local project_name
  project_name=$(basename "$PROJECT_ROOT")

  if [[ "$input" == *"$project_name/"* ]]; then
    input="${input#*${project_name}/}"
  fi

  input="${input#/}"

  input="$(echo "$input" | sed 's|\.\./||g')"

  if [[ "$input" != lib/* ]]; then
    input="lib/$input"
  fi

  echo "$PROJECT_ROOT/$input"
}


ENTITY_DIR=$(safe_dir "$ENTITY_DIR")
MODEL_DIR=$(safe_dir "$MODEL_DIR")
MAPPER_DIR=$(safe_dir "$MAPPER_DIR")

mkdir -p "$ENTITY_DIR" "$MODEL_DIR" "$MAPPER_DIR"

ENTITY_FILE="$ENTITY_DIR/${SNAKE}_entity.dart"
MODEL_FILE="$MODEL_DIR/${SNAKE}_model.dart"
MAPPER_FILE="$MAPPER_DIR/${SNAKE}_mapper.dart"

echo "🐍 Parsing JSON..."

FIELDS=$(python3 <<EOF
import json,re,sys

path = r"$PY_TMP_JSON"

def load_json_auto(p):
    raw = open(p, 'rb').read()
    for enc in ('utf-8','utf-16','utf-16le','utf-16be'):
        try:
            return json.loads(raw.decode(enc).replace("\\r",""))
        except:
            pass
    raise Exception("Cannot decode JSON")

try:
    data = load_json_auto(path)
except Exception as e:
    print("Invalid JSON:", e)
    sys.exit(1)

def t(v):
    if isinstance(v,bool): return "bool"
    if isinstance(v,int): return "int"
    if isinstance(v,float): return "double"
    if isinstance(v,list): return "List<dynamic>"
    if isinstance(v,dict): return "Map<String, dynamic>"
    return "String"

for k,v in data.items():
    camel = re.sub(r'_([a-z])', lambda m:m.group(1).upper(), k.strip())
    print(f"{k.strip()}|{camel.strip()}|{t(v).strip()}")
EOF
)

# ================= ENTITY =================
{
echo "import 'package:freezed_annotation/freezed_annotation.dart';"
echo ""
echo "part '${SNAKE}_entity.freezed.dart';"
echo "part '${SNAKE}_entity.g.dart';"
echo ""
echo "@freezed"
echo "abstract class ${NAME}Entity with _\$${NAME}Entity {"
echo "  const factory ${NAME}Entity({"

while IFS="|" read -r key camel type; do
  echo "    @JsonKey(name: '$key') required $type $camel,"
done <<< "$FIELDS"

echo "  }) = _${NAME}Entity;"
echo ""
echo "  factory ${NAME}Entity.fromJson(Map<String, dynamic> json) => _\$${NAME}EntityFromJson(json);"
echo "}"
} > "$ENTITY_FILE"

# ================= MODEL =================
{
echo "import 'package:json_annotation/json_annotation.dart';"
echo ""
echo "part '${SNAKE}_model.g.dart';"
echo ""
echo "@JsonSerializable()"
echo "class ${NAME}Model {"

while IFS="|" read -r key camel type; do
  echo "  @JsonKey(name: '$key') final $type $camel;"
done <<< "$FIELDS"

echo ""
echo "  const ${NAME}Model({"

while IFS="|" read -r key camel type; do
  echo "    required this.$camel,"
done <<< "$FIELDS"

echo "  });"
echo ""
echo "  factory ${NAME}Model.fromJson(Map<String, dynamic> json) => _\$${NAME}ModelFromJson(json);"
echo "  Map<String, dynamic> toJson() => _\$${NAME}ModelToJson(this);"
echo "}"
} > "$MODEL_FILE"

# ================= MAPPER =================

PKG_NAME=$(grep '^name:' "$PROJECT_ROOT/pubspec.yaml" | awk '{print $2}')

to_dart_import() {
  local full_path="$1"
  full_path="$(cd "$(dirname "$full_path")" && pwd)/$(basename "$full_path")"
  full_path="${full_path#$PROJECT_ROOT/}"
  full_path="${full_path#lib/}"
  echo "package:$PKG_NAME/$full_path"
}

ENTITY_IMPORT=$(to_dart_import "$ENTITY_FILE")
MODEL_IMPORT=$(to_dart_import "$MODEL_FILE")

{
cat <<EOF
import '$ENTITY_IMPORT';
import '$MODEL_IMPORT';

extension ${NAME}Mapper on ${NAME}Model {
  ${NAME}Entity toEntity() => ${NAME}Entity(
$(while IFS="|" read -r key camel type; do echo "    $camel: $camel,"; done <<< "$FIELDS")
  );
}

extension ${NAME}EntityMapper on ${NAME}Entity {
  ${NAME}Model toModel() => ${NAME}Model(
$(while IFS="|" read -r key camel type; do echo "    $camel: $camel,"; done <<< "$FIELDS")
  );
}
EOF
} > "$MAPPER_FILE"

echo "✅ Generated:"
echo "$(to_file_uri "$ENTITY_FILE")"
echo "$(to_file_uri "$MODEL_FILE")"
echo "$(to_file_uri "$MAPPER_FILE")"

read -p "Run build_runner? (y/n): " RUN
if [[ "$RUN" =~ ^[Yy]$ ]]; then
  if command -v flutter &>/dev/null; then
    flutter pub run build_runner build --delete-conflicting-outputs
  else
    echo "⚠ Flutter not found in PATH (Git Bash). Run manually."
  fi
fi

echo "🎉 DONE"
