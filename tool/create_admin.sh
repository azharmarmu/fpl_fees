#!/usr/bin/env bash
# Create Firebase Auth admin user + Firestore admins/{uid} doc for fpl-fees.
# Prerequisites: Auth Email/Password enabled in Console (Get Started → Email/Password).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT:-fpl-fees}"
ADMIN_EMAIL="${ADMIN_EMAIL:-marmuazhardev@gmail.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-fpladmin}"

API_KEY=$(python3 -c 'import json; print(json.load(open("android/app/google-services.json"))["client"][0]["api_key"][0]["current_key"])')
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

echo "Creating (or signing in) Auth user $ADMIN_EMAIL …"
curl -sS -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\",\"returnSecureToken\":true}" \
  >"$TMP"

if grep -q 'EMAIL_EXISTS' "$TMP"; then
  echo "User exists — signing in …"
  curl -sS -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\",\"returnSecureToken\":true}" \
    >"$TMP"
fi

if grep -q '"error"' "$TMP"; then
  cat "$TMP"
  echo ""
  echo "If you see OPERATION_NOT_ALLOWED / CONFIGURATION_NOT_FOUND:"
  echo "  1) Open https://console.firebase.google.com/project/${PROJECT_ID}/authentication/providers"
  echo "  2) Click Get Started → enable Email/Password"
  echo "  3) Re-run: bash tool/create_admin.sh"
  exit 1
fi

UID=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["localId"])' "$TMP")
echo "Admin UID: $UID"
echo "Writing Firestore admins/$UID …"

TOKEN=$(gcloud auth print-access-token)
curl -sS -X PATCH \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/admins/${UID}?updateMask.fieldPaths=role&updateMask.fieldPaths=email" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "x-goog-user-project: ${PROJECT_ID}" \
  -d "{\"fields\":{\"role\":{\"stringValue\":\"admin\"},\"email\":{\"stringValue\":\"${ADMIN_EMAIL}\"}}}" \
  | python3 -m json.tool | head -40

echo ""
echo "Done. Admin login in app:"
echo "  email:    $ADMIN_EMAIL"
echo "  password: $ADMIN_PASSWORD"
echo "(Local password fpladmin still works as emergency fallback when Auth fails.)"
