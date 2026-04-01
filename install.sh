#!/bin/sh
set -eu

REPO="hermetic-sys/hermetic"
BINARY="hermetic"
INSTALL_DIR="${HERMETIC_INSTALL_DIR:-$HOME/.local/bin}"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { printf "${CYAN}==>${NC} %s\n" "$1"; }
ok()    { printf "${GREEN} ✓${NC} %s\n" "$1"; }
fail()  { printf "${RED} ✗ %s${NC}\n" "$1"; exit 1; }

printf "\n"
printf "${BOLD}  ╦ ╦╔═╗╦═╗╔╦╗╔═╗╔╦╗╦╔═╗${NC}\n"
printf "${BOLD}  ╠═╣║╣ ╠╦╝║║║║╣  ║ ║║  ${NC}\n"
printf "${BOLD}  ╩ ╩╚═╝╩╚═╩ ╩╚═╝ ╩ ╩╚═╝${NC}\n"
printf "  ${CYAN}Agent-Isolated Credential Broker${NC}\n\n"

OS=$(uname -s); ARCH=$(uname -m)
case "$OS" in Linux) ;; *) fail "Hermetic supports Linux only. Got: $OS" ;; esac
case "$ARCH" in x86_64|amd64) ARCH="x86_64" ;; *) fail "Hermetic supports x86_64 only. Got: $ARCH" ;; esac

info "Finding latest release..."
LATEST=$(curl -sS "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')
[ -z "$LATEST" ] && fail "Could not find latest release. Check https://github.com/$REPO/releases"

ASSET="${BINARY}-${LATEST}-linux-${ARCH}"
URL="https://github.com/$REPO/releases/download/${LATEST}/${ASSET}"

info "Downloading Hermetic ${LATEST}..."
TMPDIR=$(mktemp -d); trap 'rm -rf "$TMPDIR"' EXIT
curl -fSL --progress-bar -o "$TMPDIR/$BINARY" "$URL" || fail "Download failed: $URL"
curl -fsSL -o "$TMPDIR/SHA256SUMS" "https://github.com/$REPO/releases/download/${LATEST}/SHA256SUMS" 2>/dev/null || true
curl -fsSL -o "$TMPDIR/${BINARY}.sig" "${URL}.sig" 2>/dev/null || true

if [ -f "$TMPDIR/SHA256SUMS" ]; then
  info "Verifying checksum..."
  EXPECTED=$(grep "$ASSET" "$TMPDIR/SHA256SUMS" | awk '{print $1}')
  ACTUAL=$(sha256sum "$TMPDIR/$BINARY" | awk '{print $1}')
  if [ -n "$EXPECTED" ] && [ "$EXPECTED" = "$ACTUAL" ]; then ok "SHA-256 verified"
  elif [ -n "$EXPECTED" ]; then fail "Checksum mismatch! Expected: $EXPECTED Got: $ACTUAL"
  fi
fi

if command -v gpg >/dev/null 2>&1 && [ -f "$TMPDIR/${BINARY}.sig" ]; then
  info "Verifying GPG signature..."
  curl -fsSL -o "$TMPDIR/key.pub" "https://github.com/$REPO/releases/download/${LATEST}/SIGNING_KEY.pub" 2>/dev/null || true
  if [ -f "$TMPDIR/key.pub" ]; then
    gpg --batch --quiet --import "$TMPDIR/key.pub" 2>/dev/null || true
    gpg --batch --verify "$TMPDIR/${BINARY}.sig" "$TMPDIR/$BINARY" 2>/dev/null && ok "GPG signature verified" || printf "  ${CYAN}ℹ GPG verification skipped${NC}\n"
  fi
else
  printf "  ${CYAN}ℹ GPG not available — skipping signature check${NC}\n"
fi

info "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
mv "$TMPDIR/$BINARY" "$INSTALL_DIR/$BINARY"
chmod +x "$INSTALL_DIR/$BINARY"

case ":$PATH:" in *":$INSTALL_DIR:"*) ;; *)
  printf "\n  ${CYAN}Add to ~/.bashrc or ~/.zshrc:${NC}\n"
  printf "    export PATH=\"\$PATH:$INSTALL_DIR\"\n\n"
  ;; esac

printf "\n"; ok "Hermetic ${LATEST} installed"
printf "\n  ${BOLD}Get started:${NC}\n"
printf "    ${GREEN}hermetic init${NC}                  Create encrypted vault\n"
printf "    ${GREEN}hermetic add --wizard${NC}          Add your first API key\n"
printf "    ${GREEN}hermetic start${NC}                 Start the daemon\n"
printf "    ${GREEN}hermetic mcp-config --install${NC}  Connect to Claude Code / Cursor\n"
printf "\n  Docs: https://hermeticsys.com/docs\n\n"
