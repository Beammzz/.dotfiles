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
  virtualisation.docker = {
    enable = true;
  };

  # Pre-create /containers with proper 1000:1000 ownership
  systemd.tmpfiles.rules = [
    "d ${ContainerPath} 0775 ${PUID} ${PGID} -"
  ];

  virtualisation.oci-containers.backend = "docker";

  # Import Docker Container Definitions
  imports = [
    (import ./Docker-Compose/traefik.nix {inherit PUID PGID Email Domain ContainerPath Timezone traefikEnvFile;})
    (import ./Docker-Compose/homepage.nix {inherit PUID PGID Domain ContainerPath MediaPath Timezone homepageEnvFile;})
    (import ./Docker-Compose/beszel.nix {inherit PUID PGID ContainerPath beszelEnvFile;})
    (import ./Docker-Compose/pi-hole.nix {inherit PUID PGID Timezone ContainerPath Domain piHoleEnvFile;})
    (import ./Docker-Compose/jellyfin.nix {inherit PUID PGID Timezone ContainerPath MediaPath;})
    (import ./Docker-Compose/seerr.nix {inherit PUID PGID Timezone ContainerPath Domain;})
    (import ./Docker-Compose/tdarr.nix {inherit PUID PGID Timezone ContainerPath MediaPath Domain Hostname;})
    (import ./Docker-Compose/arr-stacks.nix {inherit PUID PGID Timezone ContainerPath Domain MediaPath gluetunEnvFile suwayomiEnvFile;})
    (import ./Docker-Compose/gitea.nix {inherit Timezone PUID PGID Domain ContainerPath;})
    (import ./Docker-Compose/nextcloud.nix {inherit PUID PGID Timezone ContainerPath Hostname nextcloudEnvFile;})
  ];

  # Create a Docker network for proxy containers
  systemd.services.docker-create-proxy-network = {
    description = "Create Docker proxy network";
    after = ["network-online.target" "docker.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ${pkgs.docker}/bin/docker network inspect proxy >/dev/null 2>&1; then
        ${pkgs.docker}/bin/docker network create proxy
      fi
    '';
  };
}
