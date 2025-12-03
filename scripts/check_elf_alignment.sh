#!/usr/bin/env bash
# ===============================================================
# ELF Alignment Checker (16K/64K)
# ===============================================================

set -euo pipefail
progname="${0##*/}"
progname="${progname%.sh}"

# --- Colors & Icons ---
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"
CHECK="✅"
CROSS="❌"
INFO="ℹ️"
WARN="⚠️"
ARROW="➡️"

# --- Cleanup on exit ---
cleanup_trap() {
  [ -n "${tmp:-}" ] && [ -d "${tmp:-}" ] && rm -rf "${tmp}"
  exit $1
}

usage() {
  echo -e "${BOLD}Host-side ELF Alignment Checker${RESET}"
  echo "Checks if .so or ELF files are 16K or 64K aligned."
  echo
  echo "Usage:"
  echo "  ${progname} [input-path | .apk | .apex]"
  echo
  echo "Examples:"
  echo "  ${progname} ./build/lib/arm64-v8a"
  echo "  ${progname} app-release.apk"
}

# --- Argument handling ---
if [ $# -eq 0 ]; then
  echo -e "${INFO} No input path provided."
  read -rp "Enter path to directory, APK, or APEX file: " input
else
  case ${1} in
    --help | -h | -\?)
      usage
      exit 0
      ;;
    *)
      input="${1}"
      ;;
  esac
fi

if ! [ -f "${input}" -o -d "${input}" ]; then
  echo -e "${CROSS} ${RED}Invalid path:${RESET} ${input}"
  exit 1
fi

# --- Ensure tools available ---
for TOOL in file objdump unzip; do
  if ! command -v $TOOL &>/dev/null; then
    echo -e "${CROSS} Missing required tool: ${BOLD}$TOOL${RESET}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      echo -e "${INFO} Install it with: ${YELLOW}brew install binutils${RESET}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      echo -e "${INFO} Install it with: ${YELLOW}sudo apt install binutils unzip -y${RESET}"
    fi
    exit 1
  fi
done

# On macOS: prefer gobjdump (brew binutils)
if [[ "$OSTYPE" == "darwin"* && -x "/opt/homebrew/opt/binutils/bin/gobjdump" ]]; then
  alias objdump="/opt/homebrew/opt/binutils/bin/gobjdump"
fi

# --- Handle APK ---
if [[ "${input}" == *.apk ]]; then
  trap 'cleanup_trap' EXIT
  echo -e "\n${ARROW} ${BLUE}Analyzing APK:${RESET} ${input}\n"

  if command -v zipalign &>/dev/null && zipalign --help 2>&1 | grep -q "\-P <pagesize_kb>"; then
    echo -e "${INFO} Checking zip alignment (16 KB)..."
    zipalign -v -c -P 16 4 "${input}" | egrep 'lib/arm64-v8a|lib/x86_64|Verification' || true
    echo -e "${GREEN}${CHECK} Zip alignment check complete.${RESET}\n"
  else
    echo -e "${WARN} Build-tools >= 35.0.0-rc3 required for page-aligned zip check.${RESET}"
  fi

  tmp=$(mktemp -d -t apk_out_XXXX)
  unzip -qq "${input}" "lib/*" -d "${tmp}" || { echo "${CROSS} Failed to extract libs"; exit 1; }
  input="${tmp}"
fi

# --- Handle APEX ---
if [[ "${input}" == *.apex ]]; then
  trap 'cleanup_trap' EXIT
  echo -e "\n${ARROW} ${BLUE}Analyzing APEX:${RESET} ${input}\n"

  if ! command -v deapexer &>/dev/null; then
    echo -e "${CROSS} ${RED}Missing 'deapexer'. Install Android build tools or AOSP utils.${RESET}"
    exit 1
  fi

  tmp=$(mktemp -d -t apex_out_XXXX)
  deapexer extract "${input}" "${tmp}" || { echo "${CROSS} Failed to deapex."; exit 1; }
  input="${tmp}"
fi

# --- ELF alignment check ---
echo -e "\n${BOLD}🔍 ELF ALIGNMENT CHECK${RESET}"
echo "---------------------------------------------"
unaligned_libs=()
count_total=0
count_aligned=0

matches=$(find "${input}" -type f)
IFS=$'\n'
for match in $matches; do
  [[ $(file "${match}") == *"ELF"* ]] || continue
  ((count_total++))
  res=$(objdump -p "${match}" 2>/dev/null | grep LOAD | awk '{print $NF}' | head -1)

  if [[ $res =~ 2\*\*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,}) ]]; then
    ((count_aligned++))
    printf "${CHECK} ${GREEN}ALIGNED${RESET} (%-8s) → %s\n" "$res" "$match"
  else
    printf "${CROSS} ${RED}UNALIGNED${RESET} (%-8s) → %s\n" "$res" "$match"
    unaligned_libs+=("${match}")
  fi
done

echo "---------------------------------------------"
if [ ${#unaligned_libs[@]} -gt 0 ]; then
  echo -e "${WARN} ${#unaligned_libs[@]} of ${count_total} ELF files are ${RED}UNALIGNED${RESET}."
else
  echo -e "${CHECK} All ${count_total} ELF files are ${GREEN}ALIGNED${RESET}."
fi
echo "============================================="
