#!/usr/bin/env bash
# Build Flutter web release and deploy to Firebase Hosting (project fpl-fees).
#
# Usage:
#   bash tool/deploy_web.sh
#   bash tool/deploy_web.sh --skip-build   # deploy existing build/web
#
# Live URLs (after first deploy):
#   https://fpl-fees.web.app
#   https://fpl-fees.firebaseapp.com
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT:-fpl-fees}"
SKIP_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd firebase
need_cmd fvm

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  echo "==> Building Flutter web (release)..."
  fvm flutter pub get
  # Disable service worker — Firestore needs network, and SW was pinning old builds in Chrome.
  fvm flutter build web --release --pwa-strategy=none
else
  if [[ ! -f build/web/index.html ]]; then
    echo "Missing build/web — run without --skip-build first." >&2
    exit 1
  fi
  echo "==> Skipping build (using existing build/web)"
fi

echo "==> Deploying Hosting to ${PROJECT_ID}..."
firebase deploy --only hosting --project "${PROJECT_ID}"

echo ""
echo "Live:"
echo "  https://${PROJECT_ID}.web.app"
echo "  https://${PROJECT_ID}.firebaseapp.com"
echo "Console: https://console.firebase.google.com/project/${PROJECT_ID}/hosting"
