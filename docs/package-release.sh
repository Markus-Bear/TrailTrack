#!/usr/bin/env bash
# Builds the files attached to a GitHub release, into build/release:
#   TrailTrack-<tag>-source.zip   the code at the tag
#   TrailTrack-<tag>-docs.zip     the backend and app code documentation
#   TrailTrack-<tag>-debug.apk    the app, connecting to a backend on the
#                                 computer running the Android emulator
# Usage: ./docs/package-release.sh v0.1

set -euo pipefail

tag="${1:?Usage: $0 <tag>, e.g. $0 v0.1}"
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/build/release"
name="TrailTrack-$tag"

# The docs and APK are built from the working tree, so it must match the tag.
if ! git -C "$root" rev-parse -q --verify "refs/tags/$tag" > /dev/null; then
  echo "Tag $tag does not exist." >&2
  exit 1
fi
if [ "$(git -C "$root" rev-parse HEAD)" != "$(git -C "$root" rev-parse "$tag^{commit}")" ]; then
  echo "Check out $tag first: git checkout $tag" >&2
  exit 1
fi
if [ -n "$(git -C "$root" status --porcelain)" ]; then
  echo "The working tree has uncommitted changes." >&2
  exit 1
fi

rm -rf "$out"
mkdir -p "$out"

echo "Source zip"
git -C "$root" archive --format=zip --prefix="$name/" -o "$out/$name-source.zip" "$tag"

echo "Code documentation"
"$root/docs/build-docs.sh" > /dev/null
staging="$out/$name-docs"
mkdir -p "$staging"
cp -R "$root/backend/build/docs/doxygen/html" "$staging/backend"
cp -R "$root/mobile/build/docs/api" "$staging/app"
(cd "$out" && zip -qr "$name-docs.zip" "$name-docs")
rm -rf "$staging"

echo "Debug APK"
(cd "$root/mobile" && flutter build apk --debug > /dev/null)
cp "$root/mobile/build/app/outputs/flutter-apk/app-debug.apk" "$out/$name-debug.apk"

echo
ls -lh "$out"
