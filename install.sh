#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="ccswitch"

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "  ccswitch installer"
echo "  ──────────────────"
echo ""

# macOS kontrolü
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}Error: ccswitch only supports macOS (requires Keychain).${NC}"
  exit 1
fi

# claude CLI kontrolü
if ! command -v claude &>/dev/null; then
  echo -e "${YELLOW}Warning: 'claude' CLI not found in PATH.${NC}"
  echo "  Install Claude Code first: https://claude.ai/code"
  echo ""
fi

# ~/.local/bin oluştur
mkdir -p "$INSTALL_DIR"

# Script'i kopyala
cp "$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo -e "${GREEN}✓ ccswitch installed to $INSTALL_DIR/ccswitch${NC}"

# PATH kontrolü
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo -e "${YELLOW}⚠ $INSTALL_DIR is not in your PATH.${NC}"
  echo "  Add this to your ~/.zshrc or ~/.bashrc:"
  echo ""
  echo '    export PATH="$HOME/.local/bin:$PATH"'
  echo ""
  echo "  Then run: source ~/.zshrc"
else
  echo -e "${GREEN}✓ $INSTALL_DIR is already in PATH${NC}"
fi

echo ""
echo "  Get started:"
echo "    ccswitch save main        # save your current account"
echo "    ccswitch add work         # add a new account (opens browser)"
echo "    ccswitch list             # list saved profiles"
echo "    ccswitch use work         # switch to 'work' account instantly"
echo ""
