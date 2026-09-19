#!/bin/sh

set -eu

BASE_URL="https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
TOOLS_URL="$BASE_URL/tools.conf"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/bin"

curl -fsSL "$TOOLS_URL" |
while IFS='|' read -r type name source; do
  [ "$type" = "bin" ] || continue

  target="$BIN_DIR/$name"

  if [ ! -x "$target" ]; then
    echo "[INFO] Installing $name..."
    "$BIN" install "$source" "$target"
  fi
done
