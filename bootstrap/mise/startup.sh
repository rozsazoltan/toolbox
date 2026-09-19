#!/bin/sh

set -eu

BASE_URL="https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
TOOLS_URL="$BASE_URL/tools.conf"

echo "[INFO] Configuring mise..."

tools="$(curl -fsSL "$TOOLS_URL")"

printf '%s\n' "$tools" |
while IFS='|' read -r type name source; do
  [ "$type" = "mise-plugin" ] || continue

  if mise plugins ls | grep -q "^${name}[[:space:]]"; then
    echo "[SKIP] mise plugin $name already installed."
    continue
  fi

  # https://github.com/verzly/mise-php#get-started
  mise plugin install "$name" "$source"

  echo "[OK]   mise plugin $name installed."
done

# Linux/macOS normally build PHP from source.
# Use fast prebuilt static PHP instead.
# https://github.com/verzly/mise-php#prebuilt-static-php
mise config set env._.php.prebuilt_static true

printf '%s\n' "$tools" |
while IFS='|' read -r type name version; do
  [ "$type" = "mise" ] || continue

  tool="$name@$version"

  echo "[INFO] Installing $tool..."
  mise use --global "$tool"

  echo "[OK]   $tool installed."
done

echo
echo "[OK] mise tools ready."
