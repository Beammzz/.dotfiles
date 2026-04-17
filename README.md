# Harumi Homelab Dotfiles

NixOS flake configuration for a headless homelab server running Docker-based media and infrastructure services.

## Services

### Infrastructure

| Service      | Description                                |
| ------------ | ------------------------------------------ |
| **Traefik**  | Reverse proxy with Cloudflare wildcard TLS |
| **Pi-hole**  | DNS ad-blocking                            |
| **Beszel**   | System monitoring agent                    |
| **Homepage** | Dashboard for all services                 |
| **Gluetun**  | WireGuard VPN gateway for \*arr traffic    |

### Media

| Service        | Description                                   |
| -------------- | --------------------------------------------- |
| **Jellyfin**   | Media server (Intel QSV hardware transcoding)  |
| **Sonarr**     | TV show management                             |
| **Radarr**     | Movie management                               |
| **Prowlarr**   | Indexer management                              |
| **qBittorrent**| Torrent client (routed through Gluetun VPN)    |
| **Suwayomi**   | Manga reader / downloader                      |
| **FlareSolverr**| Cloudflare bypass for indexers                |
| **Seerr**      | Media request management                       |
| **Tdarr**      | Automated media transcoding                    |

### Apps

| Service       | Description            |
| ------------- | ---------------------- |
| **Gitea**     | Self-hosted Git server |
| **Nextcloud** | File sync and cloud    |

All \*arr stack + qBittorrent traffic is routed through **Gluetun** (WireGuard VPN). Secrets are managed with **sops-nix** (age encryption).

---

## Fresh Install Guide

### 1. Install NixOS

Follow the [NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation) to partition disks and install a basic system. Once you can boot and SSH in, continue below.

### 2. Clone this repo

```bash
nix-shell -p git neovim sops age
```

```bash
git clone https://github.com/Beammzz/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. Run the install script

```bash
chmod +x ./Scripts/*
./Scripts/install.sh
```

The install script walks you through everything step by step:

1. **Generate `hardware-configuration.nix`** for your machine, then open it in your editor for review
2. **Generate an age key** for sops-nix encryption
3. **Update `.sops.yaml`** with your public key
4. **Create `secrets.yaml`** from the template and encrypt it with sops
5. **Create `vars.nix`** from the template (hostname, domain, git user, etc.)
6. **Open `docker.nix`** for review
7. **Update the flake lock** and install Home Manager if needed
8. **Build and switch** to the NixOS + Home Manager configuration

> **Btrfs users:** When the script opens `hardware-configuration.nix` in your editor (step 1), add the mount options listed in the [Btrfs section](#optional-btrfs-mount-options) below before saving.

### 4. Post-install

```bash
# Set Samba password
sudo smbpasswd -a $USER

# Connect Netbird
sudo netbird up
```

---

## Day-to-Day Usage

| Command | What it does |
| --- | --- |
| `~/.dotfiles/Scripts/update.sh` | Update flake inputs, rebuild NixOS + Home Manager, optionally pull latest container images |
| `~/.dotfiles/Scripts/clean.sh` | Garbage-collect old Nix generations and prune Docker |

### Edit secrets

The age key lives at `~/.config/sops/age/keys.txt` (the default `sops` lookup path), so no extra flags are needed:

```bash
# Open encrypted secrets in your editor (re-encrypts on save)
sops Nixos/secrets.yaml

# Use a specific editor
EDITOR=nano sops Nixos/secrets.yaml

# Decrypt and print to terminal
sops -d Nixos/secrets.yaml
```

---

## Project Structure

```
~/.dotfiles/
├── flake.nix                           # Flake entry point
├── vars.nix.example                    # Template for user variables
├── .sops.yaml                          # Sops encryption rules
│
├── Scripts/
│   ├── install.sh                      # First-time setup
│   ├── update.sh                       # Flake update + rebuild
│   └── clean.sh                        # Garbage collection
│
├── Nixos/
│   ├── configuration.nix               # Main NixOS config
│   ├── secrets.nix                     # Sops-nix secret declarations
│   ├── secrets.yaml                    # Encrypted secrets (sops)
│   ├── secrets.yaml.example            # Template for secrets
│   └── Modules/
│       ├── modules.nix                 # Module imports
│       ├── hardware-configuration.nix  # Machine-specific (generated)
│       ├── samba.nix                   # Samba file sharing
│       ├── docker.nix                  # Docker + container orchestration
│       └── Docker-Compose/
│           ├── traefik.nix             # Reverse proxy
│           ├── pi-hole.nix             # DNS ad-blocking
│           ├── homepage.nix            # Dashboard
│           ├── beszel.nix              # System monitoring
│           ├── jellyfin.nix            # Media server
│           ├── arr-stacks.nix          # Gluetun + qBit + Sonarr/Radarr/Prowlarr + Suwayomi + FlareSolverr
│           ├── seerr.nix              # Media requests
│           ├── tdarr.nix               # Media transcoding
│           ├── gitea.nix               # Git server
│           └── nextcloud.nix           # File sync / cloud
│
└── Home/
    ├── home.nix                        # Home Manager entry point
    └── Modules/
        ├── modules.nix
        └── nvf.nix                     # Neovim config (nvf)
```

---

## Secrets

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age. The encrypted `secrets.yaml` is safe to commit.

| Secret | Used by |
| --- | --- |
| `cloudflare_apiToken` | Traefik (DNS challenge for wildcard TLS) |
| `pihole_password` | Pi-hole (web admin password) |
| `beszel_key` | Beszel agent (SSH public key) |
| `beszel_token` | Beszel agent (auth token) |
| `beszel_hubUrl` | Beszel agent (hub endpoint) |
| `wireguard_privateKey` | Gluetun (VPN tunnel) |
| `wireguard_presharedKey` | Gluetun (VPN tunnel) |
| `wireguard_addresses` | Gluetun (VPN tunnel) |
| `wireguard_provider` | Gluetun (VPN provider name) |
| `wireguard_type` | Gluetun (VPN protocol) |
| `wireguard_region` | Gluetun (VPN server region) |
| `suwayomi_user` | Suwayomi (basic auth username) |
| `suwayomi_password` | Suwayomi (basic auth password) |
| `nextcloud_redisPassword` | Nextcloud (Redis cache password) |
| `homepage_jellyfin_key` | Homepage (Jellyfin widget) |
| `homepage_jellyseerr_key` | Homepage (Jellyseerr widget) |
| `homepage_suwayomi_username` | Homepage (Suwayomi widget) |
| `homepage_suwayomi_password` | Homepage (Suwayomi widget) |
| `homepage_qbittorrent_username` | Homepage (qBittorrent widget) |
| `homepage_qbittorrent_password` | Homepage (qBittorrent widget) |
| `homepage_prowlarr_key` | Homepage (Prowlarr widget) |
| `homepage_sonarr_key` | Homepage (Sonarr widget) |
| `homepage_radarr_key` | Homepage (Radarr widget) |
| `homepage_pihole_key` | Homepage (Pi-hole widget) |
| `homepage_gitea_key` | Homepage (Gitea widget) |
| `homepage_beszel_username` | Homepage (Beszel widget) |
| `homepage_beszel_password` | Homepage (Beszel widget) |

**Rotate the age key:**

```bash
age-keygen -o ~/.config/sops/age/keys.txt
# Update .sops.yaml with the new public key
sops updatekeys Nixos/secrets.yaml
```

---

## Optional: Btrfs mount options

If you're using Btrfs, `nixos-generate-config` will detect your subvolumes but **won't include performance options**. When the install script opens `hardware-configuration.nix`, add these options to each Btrfs `fileSystems` entry:

```nix
# Root subvolume — zstd:1 (fast, low CPU)
fileSystems."/" = {
  device = "/dev/disk/by-uuid/YOUR-UUID";
  fsType = "btrfs";
  options = [ "compress=zstd:1" "ssd" "noatime" "discard=async" "space_cache=v2" "subvol=@" ];
};

# Home subvolume — zstd:3 (better compression ratio)
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

| Option | What it does |
| --- | --- |
| `compress=zstd:1` | Transparent compression, level 1 = fast (good for root) |
| `compress=zstd:3` | Transparent compression, level 3 = better ratio (good for data) |
| `ssd` | SSD-optimized allocation |
| `noatime` | Skip access time updates (reduces writes) |
| `discard=async` | Async TRIM for SSD longevity |
| `space_cache=v2` | Faster free-space tracking |
