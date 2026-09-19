#!/bin/sh

set -eu

BASE_URL="https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
TOOLS_URL="$BASE_URL/tools.conf"
TOOLS="$(curl -fsSL "$TOOLS_URL")"

printf '%s\n' "$TOOLS" |
while IFS='|' read -r type name source; do
  [ "$type" = "mise-plugin" ] || continue

  if ! mise plugins ls | grep -q "^${name}[[:space:]]"; then
    # https://github.com/verzly/mise-php#get-started
    mise plugin install "$name" "$source"
  fi
done

# https://github.com/verzly/mise-php#prebuilt-static-php
mise config set env._.php.prebuilt_static true

printf '%s\n' "$TOOLS" |
while IFS='|' read -r type name version; do
  [ "$type" = "mise" ] || continue
  mise use --global "$name@$version"
done
