#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════╗"
echo "║    Takumi Clean Script    ║"
echo "╚═══════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}▶ Cleaning up old user generations...${NC}"
nix-collect-garbage -d
echo -e "${BLUE}▶ Cleaning up old NixOS generations...${NC}"
sudo nix-collect-garbage -d

echo ""
echo -e "${YELLOW}${BOLD}? Prune Podman system (remove unused containers, networks, images)? (y/n)${NC}"
read -r podman_answer
if [[ "$podman_answer" == "y" ]]; then
    echo -e "${BLUE}▶ Pruning Podman system...${NC}"
    sudo podman system prune -a -f
    echo -e "${GREEN}✓ Podman system pruned.${NC}"
else
    echo -e "${YELLOW}⊘ Skipped Podman pruning.${NC}"
fi

echo -e "${GREEN}✓ Cleanup complete!${NC}"

echo ""
echo -e "${YELLOW}${BOLD}? Rebuild the configuration after cleanup? (y/n)${NC}"
read -r answer
if [[ "$answer" == "y" ]]; then
    echo -e "${BLUE}▶ Rebuilding...${NC}"
    "$DOTFILES_DIR/Scripts/update.sh"
else
    echo -e "${YELLOW}ℹ Run update.sh when you're ready to rebuild.${NC}"
fi
