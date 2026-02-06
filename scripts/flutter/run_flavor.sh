#!/usr/bin/env bash
set -e

# -----------------------
# Folder containing .env files
# -----------------------
ENV_FOLDER="../config"

# -----------------------
# Select environment
# -----------------------
FLAVOR=$1
if [ -z "$FLAVOR" ]; then
  echo "Select environment:"
  select env_choice in "dev" "stg" "prod"; do
    case $env_choice in
      dev|stg|prod)
        FLAVOR=$env_choice
        break
        ;;
      *)
        echo "Invalid selection. Choose 1,2,3 or type dev/stg/prod"
        ;;
    esac
  done
fi

# -----------------------
# Select command: run, build, or print
# -----------------------
COMMAND=$2
if [ -z "$COMMAND" ]; then
  echo "Select command:"
  select cmd_choice in "run" "build" "print"; do
    case $cmd_choice in
      run|build|print)
        COMMAND=$cmd_choice
        break
        ;;
      *)
        echo "Invalid selection. Choose 1,2,3 or type run/build/print"
        ;;
    esac
  done
fi

# -----------------------
# Check .env file exists
# -----------------------
ENV_FILE="$ENV_FOLDER/.env.$FLAVOR"
if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

echo "--------------------------------------"
echo "Loading environment from $ENV_FILE"
echo "--------------------------------------"

# -----------------------
# Generate Dart-define arguments as array
# -----------------------
DART_DEFINE_ARGS_ARRAY=()
DART_DEFINE_ARGS_ARRAY+=("--dart-define=FLAVOR=$FLAVOR")

while IFS= read -r line; do
  # Skip comment or empty
  [[ "$line" =~ ^#.*$ ]] && continue
  [[ -z "$line" ]] && continue
  key="${line%%=*}"      # part before '='
  value="${line#*=}"     # part after '='
  DART_DEFINE_ARGS_ARRAY+=("--dart-define=$key=$value")
done < "$ENV_FILE"

# -----------------------
# Build full Flutter command
# -----------------------
if [ "$COMMAND" == "run" ]; then
  FLUTTER_CMD=(flutter run -t lib/main.dart --flavor "$FLAVOR" "${DART_DEFINE_ARGS_ARRAY[@]}")
elif [ "$COMMAND" == "build" ]; then
  FLUTTER_CMD=(flutter build apk -t lib/main.dart --flavor "$FLAVOR" "${DART_DEFINE_ARGS_ARRAY[@]}")
elif [ "$COMMAND" == "print" ]; then
  FLUTTER_CMD=(flutter run -t lib/main.dart --flavor "$FLAVOR" "${DART_DEFINE_ARGS_ARRAY[@]}")
else
  echo "Unknown command: $COMMAND"
  exit 1
fi

# -----------------------
# Print and optionally execute
# -----------------------
echo "--------------------------------------"
echo "Flutter command:"
printf '%s ' "${FLUTTER_CMD[@]}"
echo ""
echo "--------------------------------------"

if [ "$COMMAND" != "print" ]; then
  "${FLUTTER_CMD[@]}"
fi
