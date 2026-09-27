#!/bin/sh
# Install mb, the Miss Blue command line.
#
#   curl -fsSL https://github.com/danest/missblue-cli/releases/latest/download/install.sh | sh
#
# macOS (Apple Silicon and Intel) and Linux (x86_64 and arm64, static). The
# download is checked against the release's SHA256SUMS before anything is
# installed; a mismatch installs nothing.
#
#   MB_VERSION=v0.2.38   install that release instead of the latest
#   MB_INSTALL_DIR=/dir  install there instead of /usr/local/bin or ~/.local/bin
#
# Run it again to update.

set -eu

REPO="danest/missblue-cli"
VERSION="${MB_VERSION:-latest}"
if [ -n "${MB_DOWNLOAD_BASE:-}" ]; then
  BASE="$MB_DOWNLOAD_BASE"
elif [ "$VERSION" = latest ]; then
  BASE="https://github.com/$REPO/releases/latest/download"
else
  BASE="https://github.com/$REPO/releases/download/$VERSION"
fi

fail() {
  echo "mb: $*" >&2
  exit 1
}

os=$(uname -s)
arch=$(uname -m)
case "$os" in
  Darwin)
    # A shell under Rosetta reports x86_64 on an Apple Silicon Mac; the
    # native build is the one to install there.
    if [ "$arch" = x86_64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = 1 ]; then
      arch=arm64
    fi
    case "$arch" in
      arm64) target=aarch64-apple-darwin ;;
      x86_64) target=x86_64-apple-darwin ;;
      *) fail "no build for macOS on $arch" ;;
    esac
    ;;
  Linux)
    case "$arch" in
      x86_64 | amd64) target=x86_64-unknown-linux-musl ;;
      aarch64 | arm64) target=aarch64-unknown-linux-musl ;;
      *) fail "no build for Linux on $arch" ;;
    esac
    ;;
  *)
    fail "this installer is for macOS and Linux. On Windows, in PowerShell:
  irm https://github.com/$REPO/releases/latest/download/install.ps1 | iex"
    ;;
esac

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  else
    fail "curl or wget is needed to download mb"
  fi
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    fail "sha256sum or shasum is needed to check the download"
  fi
}

asset="mb-$target.tar.gz"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

echo "Downloading mb for $target"
fetch "$BASE/$asset" "$tmp/$asset" || fail "could not download $BASE/$asset"
fetch "$BASE/SHA256SUMS" "$tmp/SHA256SUMS" || fail "could not download the checksums"

expected=$(awk -v name="$asset" '$2 == name || $2 == "*" name {print $1}' "$tmp/SHA256SUMS")
[ -n "$expected" ] || fail "the release lists no checksum for $asset; nothing installed"
actual=$(sha256 "$tmp/$asset")
[ "$expected" = "$actual" ] || fail "checksum mismatch for $asset; nothing installed"

tar -xzf "$tmp/$asset" -C "$tmp"
[ -f "$tmp/mb" ] || fail "the archive holds no mb binary"

if [ -n "${MB_INSTALL_DIR:-}" ]; then
  dir="$MB_INSTALL_DIR"
elif [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  dir=/usr/local/bin
else
  dir="$HOME/.local/bin"
fi
mkdir -p "$dir" || fail "cannot create $dir"

# Copied beside the old one and renamed over it, so a running mb is never
# left half-written.
cp "$tmp/mb" "$dir/.mb.$$" || fail "cannot write to $dir"
chmod 755 "$dir/.mb.$$"
mv -f "$dir/.mb.$$" "$dir/mb"
if [ "$os" = Darwin ]; then
  xattr -d com.apple.quarantine "$dir/mb" 2>/dev/null || true
fi

echo "Installed $("$dir/mb" --version) to $dir/mb"

case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    shell_name=$(basename "${SHELL:-sh}")
    case "$shell_name" in
      zsh) rc="$HOME/.zshrc" ;;
      bash) rc="$HOME/.bashrc" ;;
      fish) rc="$HOME/.config/fish/config.fish" ;;
      *) rc="$HOME/.profile" ;;
    esac
    echo
    echo "$dir is not on your PATH. Add it:"
    if [ "$shell_name" = fish ]; then
      echo "  fish_add_path $dir"
    else
      echo "  echo 'export PATH=\"$dir:\$PATH\"' >> $rc && . $rc"
    fi
    ;;
esac

echo
echo "Next: mb login"
