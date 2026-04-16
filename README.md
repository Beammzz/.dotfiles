# Harumi Homelab Dotfiles

NixOS flake configuration for a headless homelab server running Docker-based media and infrastructure services.

## Services

| Service                        | Description                                   |
| ------------------------------ | --------------------------------------------- |
| **Traefik**                    | Reverse proxy with Cloudflare wildcard TLS    |
| **Pi-hole**                    | DNS ad-blocking                               |
| **Jellyfin**                   | Media server (Intel QSV hardware transcoding) |
| **Sonarr / Radarr / Prowlarr** | TV, movie, and indexer management             |
| **qBittorrent**                | Torrent client (routed through Gluetun VPN)   |
| **Suwayomi**                   | Manga reader/downloader                       |
| **FlareSolverr**               | Cloudflare bypass for indexers                |
| **Seerr**                      | Media request management                      |
| **Tdarr**                      | Automated media transcoding                   |
| **Beszel**                     | System monitoring agent                       |
| **Homepage**                   | Dashboard                                     |

All \*arr stack + qBittorrent traffic is routed through **Gluetun** (WireGuard VPN). Secrets are managed with **sops-nix** (age encryption).

## Fresh Install Guide

### 1. Boot into a minimal NixOS installer and install NixOS

Follow the [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation) to partition disks and install a basic system. Once you can boot and SSH in, continue below.

<details>
<summary><strong>Optional: Btrfs mount options</strong></summary>

If you're using Btrfs, `nixos-generate-config` will detect your subvolumes but **won't include performance options**. Edit `Nixos/Modules/hardware-configuration.nix` and add them to each Btrfs `fileSystems` entry:

```nix
# Root subvolume — use zstd:1 (fast, low CPU)
fileSystems."/" = {
  device = "/dev/disk/by-uuid/YOUR-UUID";
  fsType = "btrfs";
  options = [ "compress=zstd:1" "ssd" "noatime" "discard=async" "space_cache=v2" "subvol=@" ];
};

# Home subvolume — use zstd:3 (better compression ratio)
fileSystems."/home" = {
  device = "/dev/disk/by-uuid/YOUR-UUID";
  fsType = "btrfs";
  options = [ "compress=zstd:3" "ssd" "noatime" "discard=async" "space_cache=v2" "subvol=@home" ];
};

# Separate media drive (if applicable)
fileSystems."/mnt/media" = {
  device = "/dev/disk/by-uuid/YOUR-MEDIA-UUID";
  fsType = "btrfs";
  options = [ "compress=zstd:3" "ssd" "noatime" "discard=async" "space_cache=v2" ];
};
```

| Option            | What it does                                                    |
| ----------------- | --------------------------------------------------------------- |
| `compress=zstd:1` | Transparent compression, level 1 = fast (good for root)         |
| `compress=zstd:3` | Transparent compression, level 3 = better ratio (good for data) |
| `ssd`             | SSD-optimized allocation                                        |
| `noatime`         | Skip access time updates (reduces writes)                       |
| `discard=async`   | Async TRIM for SSD longevity                                    |
| `space_cache=v2`  | Faster free-space tracking                                      |

</details>

### 2. Clone this repo

```bash
nix-shell -p git neovim sops age
```

```bash
git clone https://github.com/Beammzz/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. Copy your hardware configuration

If you are reinstalling on a new machine, delete any committed `Nixos/Modules/hardware-configuration.nix` first so a fresh one can be generated!

```bash
rm -f Nixos/Modules/hardware-configuration.nix
sudo nixos-generate-config --show-hardware-config > Nixos/Modules/hardware-configuration.nix
```

Edit the Nixos Hardware-Configuration.nix file before continue.

### 4. Run the install script

```bash
chmod +x ./Scripts/*
./Scripts/install.sh
```

This ensures the required tools used by `install.sh` are available in your shell (`git`, `sops`, and `age-keygen`). Home Manager is installed by the script if missing.

The install script will:

- Generate an **age key** for sops-nix (at `/var/lib/sops-nix/key.txt`)
- Update `.sops.yaml` with your public key
- Create `Nixos/secrets.yaml` from the example template
- Open your editor so you can fill in secret values
- Encrypt the secrets file with sops
- Update the flake lock
- Build and switch to the NixOS configuration
- Build and switch the Home Manager configuration

### 5. Set your Samba password

```bash
sudo smbpasswd -a $USER
```

### 6. Connect Netbird

```bash
sudo netbird up
```

## Day-to-Day Usage

### Update system (flake inputs + rebuild)

```bash
~/.dotfiles/Scripts/update.sh
```

### Clean old generations

```bash
~/.dotfiles/Scripts/clean.sh
```

### Edit or Decrypt secrets

To open and edit the secrets file in your default editor. First, ensure SOPS knows where your age key is, and since it's located in `/var/lib`, you will need to use `sudo` to read it:

```bash
sudo SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt sops Nixos/secrets.yaml
```

This decrypts in-place for editing and re-encrypts automatically on save.

If you want to use a specific editor (like `nano` or `vim`), you can set the `EDITOR` variable:

```bash
sudo EDITOR=nano SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt sops Nixos/secrets.yaml
```

To decrypt and view the file contents directly in your terminal without opening an editor:

```bash
sudo SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt sops -d Nixos/secrets.yaml
## Project Structure

```

~/.dotfiles/
├── flake.nix # Flake entry point
├── .sops.yaml # Sops encryption rules
├── README.md
├── Scripts/
│ ├── install.sh # First-time setup
│ ├── update.sh # Flake update + rebuild
│ └── clean.sh # Garbage collection
├── Nixos/
│ ├── configuration.nix # Main NixOS config
│ ├── secrets.nix # Sops-nix secret declarations
│ ├── secrets.yaml # Encrypted secrets (sops)
│ ├── secrets.yaml.example # Template for secrets
│ └── Modules/
│ ├── modules.nix # Module imports
│ ├── hardware-configuration.nix # Machine-specific (gitignored)
│ ├── samba.nix # Samba file sharing
│ ├── docker.nix # Docker + container orchestration
│ └── Docker-Compose/
│ ├── traefik.nix
│ ├── homepage.nix
│ ├── pi-hole.nix
│ ├── jellyfin.nix
│ ├── arr-stacks.nix # Gluetun + qBit + Sonarr/Radarr/Prowlarr + Suwayomi + FlareSolverr
│ ├── seerr.nix
│ ├── tdarr.nix
│ └── beszel.nix
└── Home/
├── home.nix # Home Manager entry point
└── Modules/
├── modules.nix
└── nvf.nix # Neovim config (nvf)

````

## Secrets

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age. The encrypted `secrets.yaml` is safe to commit.

| Secret                   | Used by                                  |
| ------------------------ | ---------------------------------------- |
| `cloudflare_apiToken`    | Traefik (DNS challenge for wildcard TLS) |
| `pihole_password`        | Pi-hole (web admin password)             |
| `beszel_key`             | Beszel agent (SSH public key)            |
| `beszel_token`           | Beszel agent (auth token)                |
| `beszel_hubUrl`          | Beszel agent (hub endpoint)              |
| `wireguard_privateKey`   | Gluetun (VPN tunnel)                     |
| `wireguard_presharedKey` | Gluetun (VPN tunnel)                     |
| `wireguard_addresses`    | Gluetun (VPN tunnel)                     |
| `wireguard_provider`     | Gluetun (VPN provider name)              |
| `wireguard_type`         | Gluetun (VPN protocol)                   |
| `wireguard_region`       | Gluetun (VPN server region)              |
| `suwayomi_user`          | Suwayomi (basic auth username)           |
| `suwayomi_password`      | Suwayomi (basic auth password)           |

To rotate the age key:

```bash
age-keygen -o /var/lib/sops-nix/key.txt
# Update .sops.yaml with the new public key
sops updatekeys Nixos/secrets.yaml
````
