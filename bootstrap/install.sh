#!/bin/sh

set -eu

BASE_URL="https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/bin"
MISE="$BIN_DIR/mise"

mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

if [ ! -x "$BIN" ]; then
  echo "[INFO] Installing bin..."
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT

  curl -fsSL https://github.com/marcosnils/bin/releases/latest/download/bin-linux-amd64 -o "$tmp"
  chmod +x "$tmp"
  "$tmp" install github.com/marcosnils/bin "$BIN"
fi

if [ ! -x "$MISE" ]; then
  echo "[INFO] Installing mise..."
  "$BIN" install github.com/jdx/mise "$MISE"
fi

rc="$HOME/.bashrc"
rc_dir="$HOME/.bashrc.d"

if [ "$(basename "${SHELL:-bash}")" = "zsh" ]; then
  rc="$HOME/.zshrc"
  rc_dir="$HOME/.zshrc.d"
fi

mkdir -p "$rc_dir"
touch "$rc"

cat > "$rc_dir/10-bin.sh" <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF

shell="$(basename "${SHELL:-bash}")"

cat > "$rc_dir/20-mise.sh" <<EOF
if command -v mise >/dev/null 2>&1; then
  eval "\$(mise activate $shell)"
fi
EOF

if ! grep -Fq "$rc_dir" "$rc" 2>/dev/null; then
  cat >> "$rc" <<EOF

# User specific aliases and functions
if [ -d "$rc_dir" ]; then
  for rc in "$rc_dir"/*.sh; do
    [ -f "\$rc" ] && . "\$rc"
  done
fi
EOF
fi

curl -fsSL "$BASE_URL/bin/startup.sh" | sh
curl -fsSL "$BASE_URL/mise/startup.sh" | sh

echo "[INFO] Installing Toolbox CLI..."
"$MISE" exec -- pnpm add --global "github:rozsazoltan/toolbox#master"

echo "[OK] Bootstrap complete."
echo "[INFO] Open a new shell to load environment."
