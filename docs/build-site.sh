#!/usr/bin/env bash
# Builds the project website into _site:
#   the page and its images          from site/
#   the code documentation           docs/backend and docs/app
#   the iteration reports and posters files/
#   each release's site screencast   media/
# Needs doxygen, graphviz, the Flutter SDK and the GitHub CLI.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/_site"

rm -rf "$out"
mkdir -p "$out/docs" "$out/files" "$out/media"
cp -R "$root/site/." "$out/"

echo "Code documentation"
"$root/docs/build-docs.sh" > /dev/null
cp -R "$root/backend/build/docs/doxygen/html" "$out/docs/backend"
cp -R "$root/mobile/build/docs/api" "$out/docs/app"

echo "Reports and posters"
cp "$root"/docs/iteration-reports/*.pdf "$root"/docs/posters/*.pdf "$out/files/"

echo "Screencasts"
for tag in $(gh release list --repo Markus-Bear/TrailTrack --json tagName -q '.[].tagName'); do
  # Releases without a site screencast are skipped.
  gh release download "$tag" --repo Markus-Bear/TrailTrack -p '*-screencast-site.mp4' -D "$out/media" 2> /dev/null || true
done

echo
echo "Site: $out/index.html"
