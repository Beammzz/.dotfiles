#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

commit_if_changes() {
    local message="$1"
    if ! git -C "$DOTFILES_DIR" diff --quiet || ! git -C "$DOTFILES_DIR" diff --cached --quiet; then
        git -C "$DOTFILES_DIR" add -A
        git -C "$DOTFILES_DIR" commit -m "$message"
        echo -e "${GREEN}✓ Committed:${NC} $message"
    else
        echo -e "${YELLOW}⊘ No changes to commit${NC}"
    fi
}

echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════╗"
echo "║    Takumi Update Script    ║"
echo "╚════════════════════════════╝"
echo -e "${NC}"

# Show uncommitted changes if any
if ! git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null; then
    echo -e "${BLUE}▶ Uncommitted changes:${NC}"
    if command -v nvim >/dev/null 2>&1; then
        git -C "$DOTFILES_DIR" diff | nvim -c 'set filetype=diff' -
    else
        git -C "$DOTFILES_DIR" diff | less
    fi
    echo ""
    commit_if_changes "chore: pre-update sync"
fi

echo -e "${BLUE}▶ Updating Nix Flake inputs...${NC}"
nix flake update --flake "$DOTFILES_DIR"

echo ""
echo -e "${YELLOW}${BOLD}? Build the new configuration? (y/n)${NC}"
read -r answer
if [[ "$answer" == "y" ]]; then
    commit_if_changes "chore: flake update before build"

    echo -e "${BLUE}▶ Building NixOS configuration...${NC}"
    git -C "$DOTFILES_DIR" add -f vars.nix Nixos/Modules/hardware-configuration.nix Nixos/secrets.yaml
    sudo nixos-rebuild switch --flake "$DOTFILES_DIR#Harumi-Nixos" --impure
    echo -e "${GREEN}✓ NixOS build complete.${NC}"

    echo -e "${BLUE}▶ Building Home Manager configuration...${NC}"
    home-manager switch --flake "$DOTFILES_DIR#harumi" --impure
    echo -e "${GREEN}✓ Home Manager build complete.${NC}"

    commit_if_changes "chore: post-build sync"

    echo ""
    echo -e "${YELLOW}${BOLD}? Update Podman containers to latest images? (y/n)${NC}"
    read -r podman_answer
    if [[ "$podman_answer" == "y" ]]; then
        echo -e "${BLUE}▶ Pulling latest Podman images and restarting services...${NC}"
        sudo podman ps --format "{{.Image}}" | sort -u | xargs -r -I {} sudo podman pull {}
        echo -e "${BLUE}▶ Restarting Podman infrastructure...${NC}"
        sudo systemctl restart podman.service podman-create-proxy-network.service
        echo -e "${GREEN}✓ Podman containers updated and restarted via systemd dependency tree.${NC}"
    else
        echo -e "${YELLOW}⊘ Skipped Podman update.${NC}"
    fi

    echo ""
    echo -e "${YELLOW}${BOLD}? Push changes to remote? (y/n)${NC}"
    read -r push_answer
    if [[ "$push_answer" == "y" ]]; then
        echo -e "${BLUE}▶ Pushing to remote...${NC}"
        git -C "$DOTFILES_DIR" push
        echo -e "${GREEN}✓ Pushed to remote.${NC}"
    else
        echo -e "${YELLOW}⊘ Skipped push.${NC}"
    fi

    echo -e "${GREEN}${BOLD}✓ Update complete.${NC}"
else
    echo -e "${RED}✗ Update cancelled.${NC}"
fi
