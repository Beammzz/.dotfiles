{
  pkgs,
  config,
  ...
}: let
  vars = import ../../vars.nix;

  inherit (vars) Hostname Timezone PUID PGID Email Domain ContainerPath MediaPath;

  # Sops-nix environment files (secrets injected at activation time)
  traefikEnvFile = config.sops.templates."traefik.env".path;
  piHoleEnvFile = config.sops.templates."pihole.env".path;
  beszelEnvFile = config.sops.templates."beszel.env".path;
  gluetunEnvFile = config.sops.templates."gluetun.env".path;
  suwayomiEnvFile = config.sops.templates."suwayomi.env".path;
  nextcloudEnvFile = config.sops.templates."nextcloud.env".path;
  homepageEnvFile = config.sops.templates."homepage.env".path;
in {
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  # Pre-create /containers with proper 1000:1000 ownership
  systemd.tmpfiles.rules = [
    "d ${ContainerPath} 0775 ${PUID} ${PGID} -"
  ];

  virtualisation.oci-containers.backend = "podman";

  # Import Podman Container Definitions
  imports = [
    (import ./Podman-Compose/traefik.nix {inherit PUID PGID Email Domain ContainerPath Timezone traefikEnvFile;})
    (import ./Podman-Compose/homepage.nix {inherit PUID PGID Domain ContainerPath MediaPath Timezone homepageEnvFile;})
    (import ./Podman-Compose/beszel.nix {inherit PUID PGID ContainerPath beszelEnvFile;})
    (import ./Podman-Compose/pi-hole.nix {inherit PUID PGID Timezone ContainerPath Domain piHoleEnvFile;})
    (import ./Podman-Compose/jellyfin.nix {inherit PUID PGID Timezone ContainerPath MediaPath;})
    (import ./Podman-Compose/seerr.nix {inherit PUID PGID Timezone ContainerPath Domain;})
    (import ./Podman-Compose/tdarr.nix {inherit PUID PGID Timezone ContainerPath MediaPath Domain Hostname;})
    (import ./Podman-Compose/arr-stacks.nix {inherit PUID PGID Timezone ContainerPath Domain MediaPath gluetunEnvFile suwayomiEnvFile;})
    (import ./Podman-Compose/gitea.nix {inherit Timezone PUID PGID Domain ContainerPath;})
    (import ./Podman-Compose/nextcloud.nix {inherit PUID PGID Timezone ContainerPath Hostname nextcloudEnvFile;})
  ];

  # Create a Podman network for proxy containers
  systemd.services.podman-create-proxy-network = {
    description = "Create Podman proxy network";
    after = ["network-online.target" "podman.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ${pkgs.podman}/bin/podman network inspect proxy >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman network create proxy
      fi
    '';
  };
}
