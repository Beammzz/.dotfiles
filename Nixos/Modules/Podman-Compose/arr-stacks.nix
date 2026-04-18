{
  Timezone,
  PUID,
  PGID,
  Domain,
  MediaPath,
  ContainerPath,
  gluetunEnvFile,
  suwayomiEnvFile,
  ...
}: {
  virtualisation.oci-containers.containers = {
    gluetun = {
      image = "qmcgaw/gluetun";
      autoStart = true;
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
        "--memory=192m"
        "--cpus=0.2"
        "--network=proxy"
        "--hostname=gluetun"
      ];

      environment = {
        TZ = Timezone;
        UPDATER_PERIOD = "24h";
      };

      ports = [
        "4567:4567"
      ];

      environmentFiles = [ gluetunEnvFile ];

      labels = {
        "traefik.enable" = "true";

        "traefik.http.routers.qbittorrent.rule" = "Host(`qbittorrent.${Domain}`)";
        "traefik.http.routers.qbittorrent.entrypoints" = "websecure";
        "traefik.http.routers.qbittorrent.tls" = "true";
        "traefik.http.routers.qbittorrent.tls.certresolver" = "cloudflare";
        "traefik.http.routers.qbittorrent.service" = "qbittorrent";
        "traefik.http.services.qbittorrent.loadbalancer.server.port" = "8080";

        "traefik.http.routers.sonarr.rule" = "Host(`sonarr.${Domain}`)";
        "traefik.http.routers.sonarr.entrypoints" = "websecure";
        "traefik.http.routers.sonarr.tls" = "true";
        "traefik.http.routers.sonarr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.sonarr.service" = "sonarr";
        "traefik.http.services.sonarr.loadbalancer.server.port" = "8989";

        "traefik.http.routers.radarr.rule" = "Host(`radarr.${Domain}`)";
        "traefik.http.routers.radarr.entrypoints" = "websecure";
        "traefik.http.routers.radarr.tls" = "true";
        "traefik.http.routers.radarr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.radarr.service" = "radarr";
        "traefik.http.services.radarr.loadbalancer.server.port" = "7878";

        "traefik.http.routers.prowlarr.rule" = "Host(`prowlarr.${Domain}`)";
        "traefik.http.routers.prowlarr.entrypoints" = "websecure";
        "traefik.http.routers.prowlarr.tls" = "true";
        "traefik.http.routers.prowlarr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.prowlarr.service" = "prowlarr";
        "traefik.http.services.prowlarr.loadbalancer.server.port" = "9696";

        "traefik.http.routers.suwayomi.rule" = "Host(`suwayomi.${Domain}`)";
        "traefik.http.routers.suwayomi.entrypoints" = "websecure";
        "traefik.http.routers.suwayomi.tls" = "true";
        "traefik.http.routers.suwayomi.tls.certresolver" = "cloudflare";
        "traefik.http.routers.suwayomi.service" = "suwayomi";
        "traefik.http.services.suwayomi.loadbalancer.server.port" = "4567";

        "traefik.http.routers.flaresolverr.rule" = "Host(`flaresolverr.${Domain}`)";
        "traefik.http.routers.flaresolverr.entrypoints" = "websecure";
        "traefik.http.routers.flaresolverr.tls" = "true";
        "traefik.http.routers.flaresolverr.tls.certresolver" = "cloudflare";
        "traefik.http.routers.flaresolverr.service" = "flaresolverr";
        "traefik.http.services.flaresolverr.loadbalancer.server.port" = "8191";
      };

      volumes = [
        "${ContainerPath}/gluetun:/gluetun"
      ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=512m"
        "--cpus=0.6"
      ];

      environment = {
        PUID = PUID;
        PGID = PGID;
        TZ = Timezone;
        WEBUI_PORT = "8080";
      };

      volumes = [
        "${ContainerPath}/qbittorrent:/config"
        "${ContainerPath}/qbittorrent/downloads:/downloads"
      ];
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=256m"
        "--cpus=0.4"
      ];

      environment = {
        PUID = PUID;
        PGID = PGID;
        TZ = Timezone;
      };

      volumes = [
        "${ContainerPath}/sonarr:/config"
        "${MediaPath}:/tv"
        "${ContainerPath}/qbittorrent/downloads:/downloads"
      ];
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=256m"
        "--cpus=0.4"
      ];

      environment = {
        PUID = PUID;
        PGID = PGID;
        TZ = Timezone;
      };

      volumes = [
        "${ContainerPath}/radarr:/config"
        "${MediaPath}:/movies"
        "${ContainerPath}/qbittorrent/downloads:/downloads"
      ];
    };

    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=256m"
        "--cpus=0.4"
      ];

      environment = {
        PUID = PUID;
        PGID = PGID;
        TZ = Timezone;
      };

      volumes = [
        "${ContainerPath}/prowlarr:/config"
      ];
    };

    suwayomi = {
      image = "ghcr.io/suwayomi/suwayomi-server:preview";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=512m"
        "--cpus=0.5"
      ];

      environment = {
        PUID = PUID;
        PGID = PGID;
        TZ = Timezone;
        DOWNLOAD_AS_CBZ = "true";
        AUTH_MODE = "basic_auth";
        EXTENSION_REPOS = "[\"https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json\"]";
      };

      environmentFiles = [ suwayomiEnvFile ];

      volumes = [
        "${ContainerPath}/suwayomi:/home/suwayomi/.local/share/Tachidesk"
      ];
    };

    flaresolverr = {
      image = "ghcr.io/thephaseless/byparr:latest";
      autoStart = true;
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=768m"
        "--cpus=1.5"
      ];

      environment = {
        TZ = Timezone;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${ContainerPath}/gluetun 0755 ${toString PUID} ${toString PGID} -"
    "d ${ContainerPath}/qbittorrent 0755 ${toString PUID} ${toString PGID} -"
    "d ${ContainerPath}/qbittorrent/downloads 0755 ${toString PUID} ${toString PGID} -"
    "d ${ContainerPath}/sonarr 0755 ${toString PUID} ${toString PGID} -"
    "d ${ContainerPath}/radarr 0755 ${toString PUID} ${toString PGID} -"
    "d ${ContainerPath}/prowlarr 0755 ${toString PUID} ${toString PGID} -"
    "d ${ContainerPath}/suwayomi 0755 ${toString PUID} ${toString PGID} -"
  ];

  systemd.services.podman-qbittorrent = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "podman-gluetun.service" ];
    wants = [ "podman-traefik.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-gluetun.service" ];
    bindsTo = [ "podman-gluetun.service" ];
  };

  systemd.services.podman-gluetun = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "sops-install-secrets.service" ];
    wants = [ "podman-traefik.service" "sops-install-secrets.service" ];
    requires = [ "podman-create-proxy-network.service" ];
  };

  systemd.services.podman-sonarr = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "podman-gluetun.service" ];
    wants = [ "podman-traefik.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-gluetun.service" ];
    bindsTo = [ "podman-gluetun.service" ];
  };

  systemd.services.podman-radarr = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "podman-gluetun.service" ];
    wants = [ "podman-traefik.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-gluetun.service" ];
    bindsTo = [ "podman-gluetun.service" ];
  };

  systemd.services.podman-prowlarr = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "podman-gluetun.service" ];
    wants = [ "podman-traefik.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-gluetun.service" ];
    bindsTo = [ "podman-gluetun.service" ];
  };

  systemd.services.podman-suwayomi = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "podman-gluetun.service" "sops-install-secrets.service" ];
    wants = [ "podman-traefik.service" "sops-install-secrets.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-gluetun.service" ];
    bindsTo = [ "podman-gluetun.service" ];
  };

  systemd.services.podman-flaresolverr = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" "podman-gluetun.service" ];
    wants = [ "podman-traefik.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-gluetun.service" ];
    bindsTo = [ "podman-gluetun.service" ];
  };
}
