#!/usr/bin/env bash
# Creates the upload key that signs release builds of the app.
#
# A random password is generated and stored in the macOS login Keychain
# (service "trailtrack-upload-keystore", account "upload"), then used to
# create a PKCS12 keystore with one RSA key under the alias "upload". The
# password is never printed or written to a file.
#
# Usage: docs/create-signing-key.sh "<distinguished name>" [keystore path]
# Example: docs/create-signing-key.sh "CN=Jane Doe, L=Carlow, ST=Carlow, C=IE"
#
# Keep a backup of the keystore and its password: later versions of the app
# only install over earlier ones when signed with the same key.

set -euo pipefail

SERVICE="trailtrack-upload-keystore"
ACCOUNT="upload"
ALIAS="upload"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 \"<distinguished name>\" [keystore path]" >&2
    exit 1
fi
DNAME="$1"
KEYSTORE="${2:-$HOME/trailtrack-upload-keystore.jks}"

if [[ -e "$KEYSTORE" ]]; then
    echo "$KEYSTORE already exists; refusing to replace it." >&2
    exit 1
fi
if security find-generic-password -s "$SERVICE" -a "$ACCOUNT" >/dev/null 2>&1; then
    echo "The Keychain already has a \"$SERVICE\" password; refusing to replace it." >&2
    exit 1
fi

# 32 letters and digits, about 190 bits.
KEYSTORE_PASSWORD="$(openssl rand -base64 96 | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 32)"
export KEYSTORE_PASSWORD
if [[ ${#KEYSTORE_PASSWORD} -ne 32 ]]; then
    echo "Could not generate a password." >&2
    exit 1
fi

# Fed through "security -i" so the password never appears in a process list.
printf 'add-generic-password -s %s -a %s -l "TrailTrack upload keystore" -j "Password for %s, key alias %s" -w %s\n' \
    "$SERVICE" "$ACCOUNT" "$KEYSTORE" "$ALIAS" "$KEYSTORE_PASSWORD" | security -i >/dev/null

if ! keytool -genkeypair -v \
        -keystore "$KEYSTORE" -storetype PKCS12 \
        -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "$DNAME" \
        -storepass:env KEYSTORE_PASSWORD; then
    security delete-generic-password -s "$SERVICE" -a "$ACCOUNT" >/dev/null
    echo "keytool failed; the Keychain entry was removed." >&2
    exit 1
fi
chmod 600 "$KEYSTORE"
unset KEYSTORE_PASSWORD

# Opens the keystore with the password read back from the Keychain, which
# proves the two match.
KEYSTORE_PASSWORD="$(security find-generic-password -s "$SERVICE" -a "$ACCOUNT" -w)"
export KEYSTORE_PASSWORD
keytool -list -v -keystore "$KEYSTORE" -storepass:env KEYSTORE_PASSWORD -alias "$ALIAS" \
    | grep -E "Owner:|Valid from|SHA256:"
unset KEYSTORE_PASSWORD

echo "Created $KEYSTORE; its password is in the login Keychain as \"$SERVICE\"."
