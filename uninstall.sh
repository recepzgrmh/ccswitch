#!/bin/bash

INSTALL_DIR="$HOME/.local/bin"
KEYCHAIN_PROFILES_SERVICE="ccswitch-profiles"
INDEX_FILE="$HOME/.claude/ccswitch-index.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "  ccswitch uninstaller"
echo "  ────────────────────"
echo ""

# Remove binary
if [[ -f "$INSTALL_DIR/ccswitch" ]]; then
  rm "$INSTALL_DIR/ccswitch"
  echo -e "${GREEN}✓ removed $INSTALL_DIR/ccswitch${NC}"
else
  echo "  ccswitch binary not found at $INSTALL_DIR/ccswitch (already removed?)"
fi

# Remove index file
if [[ -f "$INDEX_FILE" ]]; then
  echo ""
  read -r -p "  Remove saved profile index (~/.claude/ccswitch-index.json)? [y/N]: " answer
  if [[ "${answer,,}" == "y" ]]; then
    rm "$INDEX_FILE"
    echo -e "${GREEN}✓ removed $INDEX_FILE${NC}"
  else
    echo "  Kept $INDEX_FILE"
  fi
fi

# Remove Keychain entries
echo ""
read -r -p "  Remove all saved profiles from Keychain? [y/N]: " answer
if [[ "${answer,,}" == "y" ]]; then
  count=0
  # Find all entries with our service name
  while IFS= read -r acct; do
    security delete-generic-password -s "$KEYCHAIN_PROFILES_SERVICE" -a "$acct" 2>/dev/null && ((count++)) || true
  done < <(security dump-keychain 2>/dev/null \
    | grep -A2 "\"$KEYCHAIN_PROFILES_SERVICE\"" \
    | grep '"acct"' \
    | sed 's/.*"acct"<blob>="\([^"]*\)".*/\1/')

  if [[ $count -gt 0 ]]; then
    echo -e "${GREEN}✓ removed $count profile(s) from Keychain${NC}"
  else
    echo "  No Keychain entries found."
  fi
else
  echo "  Kept Keychain entries."
fi

echo ""
echo -e "${GREEN}Done.${NC} Your active Claude Code session was not affected."
echo ""
