#!/bin/sh

set -eu

BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/bin"
MISE="$BIN_DIR/mise"

echo "[INFO] Preparing bootstrap..."

mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

if [ ! -x "$BIN" ]; then
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      arch="x86_64"
      ;;
    arm64|aarch64)
      arch="arm64"
      ;;
    *)
      echo "[ERR] Unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac

  url="$(
    curl -fsSL https://api.github.com/repos/marcosnils/bin/releases/latest |
      grep browser_download_url |
      cut -d '"' -f 4 |
      grep -Ei "${os}.*${arch}" |
      head -n 1
  )"

  [ -n "$url" ] || {
    echo "[ERR] Unable to find compatible bin release." >&2
    exit 1
  }

  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT

  curl -fsSL "$url" -o "$tmp"
  chmod +x "$tmp"

  "$tmp" install github.com/marcosnils/bin "$BIN"

  echo "[OK] bin installed."
fi

if [ ! -x "$MISE" ]; then
  "$BIN" install github.com/jdx/mise "$MISE"

  echo "[OK] mise installed."
fi

shell="$(basename "${SHELL:-bash}")"

case "$shell" in
  zsh)
    rc="$HOME/.zshrc"
    rc_dir="$HOME/.zshrc.d"
    ;;
  *)
    shell="bash"
    rc="$HOME/.bashrc"
    rc_dir="$HOME/.bashrc.d"
    ;;
esac

mkdir -p "$rc_dir"
touch "$rc"

cat > "$rc_dir/10-bin.sh" <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF

cat > "$rc_dir/20-mise.sh" <<EOF
if command -v mise >/dev/null 2>&1; then
  eval "\$(mise activate $shell)"
fi
EOF

loader="for rc in \"$rc_dir\"/*.sh; do [ -f \"\$rc\" ] && . \"\$rc\"; done"

if ! grep -Fq "$rc_dir" "$rc"; then
  cat >> "$rc" <<EOF

# User specific aliases and functions
if [ -d "$rc_dir" ]; then
  $loader
fi
EOF
fi

echo
"$BIN" --version
"$MISE" --version
echo
echo "[OK] Bootstrap complete."
echo "[INFO] Open new shell to load environment."

BASE_URL="https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"

curl -fsSL "$BASE_URL/bin/startup.sh" | sh
curl -fsSL "$BASE_URL/mise/startup.sh" | sh
