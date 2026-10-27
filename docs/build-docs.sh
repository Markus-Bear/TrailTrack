#!/usr/bin/env bash
# Builds the code documentation as HTML:
#   backend/build/docs/doxygen/html   the backend, with Doxygen
#   mobile/build/docs/api             the app, with dart doc
# Needs doxygen, graphviz (for the class diagrams) and the Flutter SDK.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
export TRAILTRACK_VERSION="$(git -C "$root" describe --tags --always)"

echo "Backend: Doxygen"
cd "$root/backend"
rm -rf build/docs/doxygen
mkdir -p build/docs
doxygen

echo "App: dart doc"
cd "$root/mobile"
dart doc --output build/docs/api > /dev/null

echo
echo "Backend: $root/backend/build/docs/doxygen/html/index.html"
echo "App:     $root/mobile/build/docs/api/index.html"
echo "Doxygen warnings: $root/backend/build/docs/doxygen-warnings.txt"
