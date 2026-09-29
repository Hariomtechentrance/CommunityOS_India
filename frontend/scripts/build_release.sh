#!/usr/bin/env bash
# Builds the release Android app bundle wired up to the real backend.
#
# `API_BASE_URL` defaults to the production backend so a plain `flutter build`
# can never silently ship pointing at localhost (see api_client.dart) - the
# bug that broke login for every Play Store internal tester. Override it for
# a staging build with: API_BASE_URL=https://staging... ./scripts/build_release.sh
set -euo pipefail

cd "$(dirname "$0")/.."

API_BASE_URL="${API_BASE_URL:-https://communityos-india.onrender.com}"

if [ ! -f android/key.properties ]; then
  echo "error: android/key.properties not found - release build would fall back to debug signing." >&2
  exit 1
fi

echo "Building release AAB with API_BASE_URL=$API_BASE_URL"
flutter build appbundle --release --dart-define="API_BASE_URL=$API_BASE_URL"
