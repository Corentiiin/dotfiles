#!/bin/sh
# Rebuilds the installed sketchybar version from source with the *.patch files
# of this folder, puts it in place of the Homebrew binary and restarts the bar.
# Run it again after every `brew upgrade sketchybar`.
# Undo: brew reinstall sketchybar
set -eu

here=$(cd "$(dirname "$0")" && pwd)
version=$(sketchybar --version | sed 's/^sketchybar-//')
binary="$(brew --prefix sketchybar)/bin/sketchybar"

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

echo "Building sketchybar $version with: $(cd "$here" && ls *.patch | tr '\n' ' ')"
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$version" https://github.com/FelixKratz/SketchyBar.git "$build/src"
for patch in "$here"/*.patch; do
  git -C "$build/src" apply "$patch"
done
case "$(uname -m)" in
  arm64) target=arm64 ;;
  *)     target=x86 ;;
esac
make -C "$build/src" "$target" >/dev/null

# The Homebrew binary is read-only
chmod u+w "$binary"
cp "$build/src/bin/sketchybar" "$binary"
chmod 555 "$binary"

launchctl kickstart -k "gui/$(id -u)/sh.brew.sketchybar"
echo "Done: $binary"
