#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SOPS_KEY_DIR="$HOME/.config/sops/age"
SOPS_KEY_FILE="$SOPS_KEY_DIR/keys.txt"
SOPS_CONFIG="$DOTFILES_DIR/.sops.yaml"
SECRETS_EXAMPLE="$DOTFILES_DIR/Nixos/secrets.yaml.example"
SECRETS_FILE="$DOTFILES_DIR/Nixos/secrets.yaml"
HARDWARE_CONFIG="$DOTFILES_DIR/Nixos/Modules/hardware-configuration.nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}▶ $1${NC}"; }
ok()    { echo -e "${GREEN}✓ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; exit 1; }

echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════╗"
echo "║    Takumi Install Script     ║"
echo "╚══════════════════════════════╝"
echo -e "${NC}"

# ── 1. Hardware Configuration ──────────────────────────────────────────
if [[ ! -f "$HARDWARE_CONFIG" ]]; then
    info "Generating hardware-configuration.nix..."
    sudo nixos-generate-config --show-hardware-config > "$HARDWARE_CONFIG"
    ok "Hardware configuration generated."
else
    ok "Hardware configuration already exists, skipping."
fi

info "Review your hardware-configuration.nix before continuing."
echo -e "${CYAN}  If you use Btrfs, add mount options now (see README.md for details).${NC}"
echo -e "${YELLOW}? Press Enter to open hardware-configuration.nix in your editor...${NC}"
read -r
${EDITOR:-nano} "$HARDWARE_CONFIG"
ok "Hardware configuration reviewed."

# ── 2. Age Key Setup ──────────────────────────────────────────────────
if [[ -f "$SOPS_KEY_FILE" ]]; then
    ok "Age key already exists at $SOPS_KEY_FILE"
    if [[ -r "$SOPS_KEY_FILE" ]]; then
        AGE_PUBLIC_KEY=$(grep -o 'age1[a-z0-9]*' "$SOPS_KEY_FILE" | head -1 || true)
    else
        warn "Age key is not readable without sudo. Reading with elevated permissions."
        AGE_PUBLIC_KEY=$(sudo grep -o 'age1[a-z0-9]*' "$SOPS_KEY_FILE" | head -1 || true)
    fi
    if [[ -z "$AGE_PUBLIC_KEY" ]]; then
        # Extract public key from the private key
        if [[ -r "$SOPS_KEY_FILE" ]]; then
            AGE_PUBLIC_KEY=$(age-keygen -y "$SOPS_KEY_FILE" 2>/dev/null || true)
        else
            AGE_PUBLIC_KEY=$(sudo age-keygen -y "$SOPS_KEY_FILE" 2>/dev/null || true)
        fi
    fi
else
    info "Generating age key for sops-nix..."
    mkdir -p "$SOPS_KEY_DIR"
    # Generate key, capture output to extract public key
    AGE_OUTPUT=$(age-keygen -o "$SOPS_KEY_FILE" 2>&1)
    chmod 600 "$SOPS_KEY_FILE"
    ok "Age key created at $SOPS_KEY_FILE"

    AGE_PUBLIC_KEY=$(echo "$AGE_OUTPUT" | grep -o 'age1[a-z0-9]*' | head -1)
    if [[ -z "$AGE_PUBLIC_KEY" ]]; then
        AGE_PUBLIC_KEY=$(age-keygen -y "$SOPS_KEY_FILE" 2>/dev/null)
    fi
fi

if [[ -z "${AGE_PUBLIC_KEY:-}" ]]; then
    error "Could not determine age public key. Check $SOPS_KEY_FILE"
fi

echo -e "${CYAN}  Age public key: ${BOLD}$AGE_PUBLIC_KEY${NC}"

# ── 3. Update .sops.yaml with the real public key ─────────────────────
if grep -q "$AGE_PUBLIC_KEY" "$SOPS_CONFIG" 2>/dev/null; then
    ok ".sops.yaml already has the correct public key."
else
    info "Updating .sops.yaml with your age public key..."
    sed -i "s|age1[a-z0-9x]\{1,\}|$AGE_PUBLIC_KEY|g" "$SOPS_CONFIG"
    ok ".sops.yaml updated."
fi

# ── 4. Create and encrypt secrets.yaml ────────────────────────────────
if [[ -f "$SECRETS_FILE" ]]; then
    ok "secrets.yaml already exists. Run 'sops $SECRETS_FILE' to edit."
else
    info "Creating secrets.yaml from template..."
    cp "$SECRETS_EXAMPLE" "$SECRETS_FILE"

    echo ""
    echo -e "${YELLOW}${BOLD}  Fill in your secret values in the editor that opens next."
    echo -e "  Save and close when done.${NC}"
    echo ""
    echo -e "${YELLOW}? Press Enter to open the editor...${NC}"
    read -r

    ${EDITOR:-nano} "$SECRETS_FILE"

    info "Encrypting secrets.yaml with sops..."
    sops --encrypt --in-place "$SECRETS_FILE"
    ok "secrets.yaml encrypted."
fi

# ── 4.5. Create vars.nix ──────────────────────────────────────────────
VARS_EXAMPLE="$DOTFILES_DIR/vars.nix.example"
VARS_FILE="$DOTFILES_DIR/vars.nix"

if [[ -f "$VARS_FILE" ]]; then
    ok "vars.nix already exists."
else
    info "Creating vars.nix from template..."
    cp "$VARS_EXAMPLE" "$VARS_FILE"
    
    echo ""
    echo -e "${YELLOW}${BOLD}  Fill in your variables in the editor that opens next."
    echo -e "  Save and close when done.${NC}"
    echo ""
    
    echo -e "${YELLOW}? Press Enter to open the editor...${NC}"
    read -r
    
    ${EDITOR:-nano} "$VARS_FILE"
    ok "vars.nix configured."
fi

# ── 5. Edit podman.nix ────────────────────────────────────────────────
info "Please review and edit podman.nix before continuing."
echo -e "${YELLOW}? Press Enter to open podman.nix in your editor...${NC}"
read -r
${EDITOR:-nano} "$DOTFILES_DIR/Nixos/Modules/podman.nix"
ok "podman.nix reviewed."

# ── 6. Update flake lock ──────────────────────────────────────────────
info "Updating flake lock file..."
nix --extra-experimental-features "nix-command flakes" flake update --flake "$DOTFILES_DIR"
ok "Flake lock updated."

# ── 7. Ensure Home Manager is available ───────────────────────────────
if ! command -v home-manager >/dev/null 2>&1; then
    info "Home Manager not found. Installing via nix-channel..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
    export PATH="$HOME/.nix-profile/bin:$PATH"
fi

if ! command -v home-manager >/dev/null 2>&1; then
    error "Home Manager is still unavailable after install. Open a new shell and rerun the script."
fi

ok "Home Manager is available."

# ── 8. Build NixOS ────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}${BOLD}? Build and switch to the NixOS configuration now? (y/n)${NC}"
read -r answer
if [[ "$answer" == "y" ]]; then
    info "Building NixOS configuration..."
    git -C "$DOTFILES_DIR" add .
    git -C "$DOTFILES_DIR" add -f vars.nix Nixos/Modules/hardware-configuration.nix Nixos/secrets.yaml
    sudo nixos-rebuild switch --flake "$DOTFILES_DIR#Harumi-Nixos" --impure
    ok "NixOS configuration applied."

    info "Building Home Manager configuration..."
    home-manager switch --flake "$DOTFILES_DIR#harumi" --impure
    ok "Home Manager configuration applied."
else
    warn "Skipped build. Run manually when ready:"
    echo "  sudo nixos-rebuild switch --flake $DOTFILES_DIR#Harumi-Nixos --impure"
    echo "  home-manager switch --flake $DOTFILES_DIR#harumi --impure"
fi

# ── 9. Post-install reminders ─────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════╗"
echo "║     Installation Complete!       ║"
echo "╚══════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}  Post-install steps:${NC}"
echo -e "  1. Set Samba password:  ${BOLD}sudo smbpasswd -a harumi${NC}"
echo -e "  2. Connect Netbird:     ${BOLD}sudo netbird up${NC}"
echo -e "  3. Edit secrets later:  ${BOLD}sops $SECRETS_FILE${NC}"
echo ""
