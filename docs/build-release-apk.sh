#!/usr/bin/env bash
# Builds signed release APKs of the app, one per CPU architecture, that talk
# to the given backend.
#
# The keystore password is read from the macOS login Keychain entry made by
# docs/create-signing-key.sh. The APKs are written to
# mobile/build/app/outputs/flutter-apk/.
#
# Usage: docs/build-release-apk.sh <API base URL> [keystore path]
# Example: docs/build-release-apk.sh https://example.herokuapp.com

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <API base URL> [keystore path]" >&2
    exit 1
fi
API_BASE_URL="${1%/}"
TRAILTRACK_KEYSTORE="${2:-$HOME/trailtrack-upload-keystore.jks}"

if [[ "$API_BASE_URL" != https://* ]]; then
    echo "The API base URL must use https: release builds do not allow plain http." >&2
    exit 1
fi
if [[ ! -f "$TRAILTRACK_KEYSTORE" ]]; then
    echo "No keystore at $TRAILTRACK_KEYSTORE; create one with docs/create-signing-key.sh." >&2
    exit 1
fi

TRAILTRACK_KEYSTORE_PASSWORD="$(security find-generic-password -s trailtrack-upload-keystore -a upload -w)"
export TRAILTRACK_KEYSTORE TRAILTRACK_KEYSTORE_PASSWORD

cd "$(dirname "$0")/../mobile"
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL="$API_BASE_URL"

# Confirms each APK is signed with the upload key, not the debug key.
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
APKSIGNER="$(ls -d "$SDK"/build-tools/*/apksigner | sort -V | tail -n 1)"
EXPECTED="$(keytool -list -v -keystore "$TRAILTRACK_KEYSTORE" -storepass:env TRAILTRACK_KEYSTORE_PASSWORD -alias upload \
    | awk '/SHA256:/ {print $2}' | tr -d ':' | tr '[:upper:]' '[:lower:]')"
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    actual="$("$APKSIGNER" verify --print-certs "$apk" | awk -F': ' '/SHA-256 digest/ {print $2; exit}')"
    if [[ "$actual" != "$EXPECTED" ]]; then
        echo "$apk is not signed with the upload key." >&2
        exit 1
    fi
    echo "$(basename "$apk"): signed with the upload key, $(du -h "$apk" | cut -f1)"
done
