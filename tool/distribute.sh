#!/usr/bin/env bash
# Build and upload FPL Fees to Firebase App Distribution (Android APK + iOS IPA).
#
# Usage:
#   bash tool/distribute.sh
#   bash tool/distribute.sh --group testers --notes "Weekly fee fix"
#   bash tool/distribute.sh --platform android
#   bash tool/distribute.sh --platform ios --notes-file notes.txt
#   bash tool/distribute.sh --skip-build   # upload existing artifacts only
#
# Env overrides:
#   FIREBASE_PROJECT, ANDROID_APP_ID, IOS_APP_ID, GROUP, NOTES, PLATFORM
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT:-fpl-fees}"
ANDROID_APP_ID="${ANDROID_APP_ID:-1:283215487299:android:c17cf44bf9cd9e2c8b4ff6}"
IOS_APP_ID="${IOS_APP_ID:-1:283215487299:ios:c6c8722ad48fb7df8b4ff6}"
GROUP="${GROUP:-testers}"
PLATFORM="${PLATFORM:-both}" # both | android | ios
NOTES="${NOTES:-}"
NOTES_FILE=""
SKIP_BUILD=0
IOS_EXPORT_METHOD="${IOS_EXPORT_METHOD:-ad-hoc}" # ad-hoc | development | enterprise | app-store

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --group|-g)
      GROUP="$2"
      shift 2
      ;;
    --notes|-n)
      NOTES="$2"
      shift 2
      ;;
    --notes-file)
      NOTES_FILE="$2"
      shift 2
      ;;
    --platform|-p)
      PLATFORM="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --ios-export)
      IOS_EXPORT_METHOD="$2"
      shift 2
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage 1
      ;;
  esac
done

case "$PLATFORM" in
  both|android|ios) ;;
  *)
    echo "PLATFORM must be both, android, or ios (got: $PLATFORM)" >&2
    exit 1
    ;;
esac

if [[ -n "$NOTES_FILE" ]]; then
  if [[ ! -f "$NOTES_FILE" ]]; then
    echo "Notes file not found: $NOTES_FILE" >&2
    exit 1
  fi
  NOTES="$(cat "$NOTES_FILE")"
fi

if [[ -z "$NOTES" ]]; then
  NOTES="FPL Fees Season 2 — $(date +%Y-%m-%d)"
fi

NOTES_TMP="$(mktemp)"
trap 'rm -f "$NOTES_TMP"' EXIT
printf '%s\n' "$NOTES" >"$NOTES_TMP"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd firebase
if [[ "$SKIP_BUILD" -eq 0 ]]; then
  need_cmd fvm
fi

export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"

build_android() {
  echo "==> Building Android release APK…"
  fvm flutter build apk --release
}

build_ios() {
  echo "==> Building iOS IPA (export-method: $IOS_EXPORT_METHOD)…"
  fvm flutter build ipa --release --export-method "$IOS_EXPORT_METHOD"
}

find_ipa() {
  local ipa
  ipa="$(find build/ios/ipa -name '*.ipa' -type f 2>/dev/null | head -n 1 || true)"
  if [[ -z "$ipa" ]]; then
    echo "No IPA found under build/ios/ipa" >&2
    exit 1
  fi
  echo "$ipa"
}

distribute_android() {
  local apk="build/app/outputs/flutter-apk/app-release.apk"
  if [[ ! -f "$apk" ]]; then
    echo "Missing APK: $apk" >&2
    exit 1
  fi
  echo "==> Uploading Android → group '$GROUP'…"
  firebase appdistribution:distribute "$apk" \
    --project "$PROJECT_ID" \
    --app "$ANDROID_APP_ID" \
    --groups "$GROUP" \
    --release-notes-file "$NOTES_TMP"
}

distribute_ios() {
  local ipa
  ipa="$(find_ipa)"
  echo "==> Uploading iOS ($ipa) → group '$GROUP'…"
  firebase appdistribution:distribute "$ipa" \
    --project "$PROJECT_ID" \
    --app "$IOS_APP_ID" \
    --groups "$GROUP" \
    --release-notes-file "$NOTES_TMP"
}

echo "Project:  $PROJECT_ID"
echo "Group:    $GROUP"
echo "Platform: $PLATFORM"
echo "Notes:"
sed 's/^/  /' "$NOTES_TMP"
echo ""

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  fvm flutter pub get
  case "$PLATFORM" in
    both)
      build_android
      build_ios
      ;;
    android) build_android ;;
    ios) build_ios ;;
  esac
fi

case "$PLATFORM" in
  both)
    distribute_android
    distribute_ios
    ;;
  android) distribute_android ;;
  ios) distribute_ios ;;
esac

echo ""
echo "Done. Console: https://console.firebase.google.com/project/${PROJECT_ID}/appdistribution"
