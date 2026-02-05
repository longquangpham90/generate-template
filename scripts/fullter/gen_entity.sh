#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# ================= PACKAGE NAME =================
PACKAGE_NAME=$(grep '^name:' pubspec.yaml | head -n1 | awk '{print $2}')

# ================= UTILS =================
normalize_dir() {
  local INPUT="$1"
  if [[ "$INPUT" != /* ]]; then INPUT="$PROJECT_ROOT/$INPUT"; fi
  ABS=$(cd "$INPUT" && pwd)
  python3 - <<END
import os
print(os.path.relpath("$ABS", "$PROJECT_ROOT"))
END
}

to_package_import() {
  local FILE_PATH="$1"
  local REL="${FILE_PATH#lib/}"
  echo "package:$PACKAGE_NAME/$REL"
}

read_clipboard() {
  command -v pbpaste &>/dev/null && pbpaste && return
  command -v wl-paste &>/dev/null && wl-paste && return
  command -v xclip &>/dev/null && xclip -selection clipboard -o && return
  echo "❌ No clipboard tool"; exit 1
}

command -v jq >/dev/null || { echo "❌ jq not installed"; exit 1; }

# ================= READ JSON =================
RAW_JSON=$(read_clipboard)
echo "$RAW_JSON" | jq . >/dev/null || { echo "❌ Invalid JSON"; exit 1; }

read -p "👉 Base name: " NAME
[ -z "$NAME" ] && NAME="Entity"

SNAKE=$(echo "$NAME" | sed -E 's/([a-z])([A-Z])/\1_\2/g' | tr 'A-Z' 'a-z')

read -p "📁 Entity dir: " ENTITY_DIR
read -p "📁 Model dir: " MODEL_DIR
read -p "📁 Mapper dir: " MAPPER_DIR

ENTITY_DIR=$(normalize_dir "$ENTITY_DIR")
MODEL_DIR=$(normalize_dir "$MODEL_DIR")
MAPPER_DIR=$(normalize_dir "$MAPPER_DIR")

mkdir -p "$ENTITY_DIR" "$MODEL_DIR" "$MAPPER_DIR"

ENTITY_FILE="$ENTITY_DIR/${SNAKE}_entity.dart"
MODEL_FILE="$MODEL_DIR/${SNAKE}_model.dart"
MAPPER_FILE="$MAPPER_DIR/${SNAKE}_mapper.dart"

ENTITY_IMPORT=$(to_package_import "$ENTITY_FILE")
MODEL_IMPORT=$(to_package_import "$MODEL_FILE")

# ================= EXTRACT FIELDS =================
FIELDS=$(echo "$RAW_JSON" | jq -r 'to_entries[] | "\(.key):\(.value|type)"')

map_type() {
  case "$1" in
    string) echo "String" ;;
    number) echo "num" ;;
    boolean) echo "bool" ;;
    object) echo "Map<String, dynamic>" ;;
    array) echo "List<dynamic>" ;;
    null) echo "dynamic" ;;
    *) echo "dynamic" ;;
  esac
}

# ================= ENTITY =================
cat > "$ENTITY_FILE" <<EOF
import 'package:freezed_annotation/freezed_annotation.dart';

part '${SNAKE}_entity.freezed.dart';
part '${SNAKE}_entity.g.dart';

@freezed
abstract class ${NAME}Entity with _\$${NAME}Entity {
  const factory ${NAME}Entity({
EOF

while read -r row; do
  key="${row%%:*}"
  type=$(map_type "${row##*:}")
  echo "    @JsonKey(name: '$key') required $type $key," >> "$ENTITY_FILE"
done <<< "$FIELDS"

cat >> "$ENTITY_FILE" <<EOF
  }) = _${NAME}Entity;

  factory ${NAME}Entity.fromJson(Map<String, dynamic> json) =>
      _\$${NAME}EntityFromJson(json);
}
EOF

# ================= MODEL =================
cat > "$MODEL_FILE" <<EOF
import 'package:json_annotation/json_annotation.dart';

part '${SNAKE}_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ${NAME}Model {
EOF

# ===== fields
while read -r row; do
  key="${row%%:*}"
  type=$(map_type "${row##*:}")
  camel=$(echo "$key" | sed -E 's/_([a-z])/\U\1/g')

  if [[ "$key" != "$camel" ]]; then
    echo "  @JsonKey(name: '$key')" >> "$MODEL_FILE"
    echo "  final $type $camel;" >> "$MODEL_FILE"
  else
    echo "  final $type $key;" >> "$MODEL_FILE"
  fi
done <<< "$FIELDS"

cat >> "$MODEL_FILE" <<EOF

  const ${NAME}Model({
EOF

while read -r row; do
  key="${row%%:*}"
  camel=$(echo "$key" | sed -E 's/_([a-z])/\U\1/g')
  echo "    required this.$camel," >> "$MODEL_FILE"
done <<< "$FIELDS"

cat >> "$MODEL_FILE" <<EOF
  });

  factory ${NAME}Model.fromJson(Map<String, dynamic> json) =>
      _\$${NAME}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${NAME}ModelToJson(this);
}
EOF

# ================= MAPPER =================
cat > "$MAPPER_FILE" <<EOF
import '$ENTITY_IMPORT';
import '$MODEL_IMPORT';

extension ${NAME}ModelMapper on ${NAME}Model {
  ${NAME}Entity toEntity() {
    return ${NAME}Entity(
EOF

while read -r row; do
  key="${row%%:*}"
  echo "      $key: $key," >> "$MAPPER_FILE"
done <<< "$FIELDS"

cat >> "$MAPPER_FILE" <<EOF
    );
  }
}

extension ${NAME}EntityMapper on ${NAME}Entity {
  ${NAME}Model toModel() {
    return ${NAME}Model(
EOF

while read -r row; do
  key="${row%%:*}"
  echo "      $key: $key," >> "$MAPPER_FILE"
done <<< "$FIELDS"

cat >> "$MAPPER_FILE" <<EOF
    );
  }
}
EOF

# ================= FINISH =================
echo ""
echo "✅ Generated:"
echo " - $ENTITY_FILE"
echo " - $MODEL_FILE"
echo " - $MAPPER_FILE"
echo ""

read -p "🚀 Run build_runner now? (yes/no): " RUN_BUILD

if [[ "$RUN_BUILD" == "yes" || "$RUN_BUILD" == "y" ]]; then
  echo ""
  echo "▶ Running build_runner..."
  flutter pub run build_runner build --delete-conflicting-outputs

  echo ""
  echo "🎉 Code generation completed!"
else
  echo ""
  echo "⏭️  Skip build_runner."
fi
