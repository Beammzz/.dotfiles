{ PUID, PGID, Timezone, ContainerPath, Domain, ... }: {
  virtualisation.oci-containers.containers.seerr = {
    image = "ghcr.io/seerr-team/seerr:latest";
    autoStart = true;
    extraOptions = [
        "--memory=512m"
        "--cpus=0.6"
        "--network=proxy"
        "--security-opt=no-new-privileges:true"
    ];

    environment = {
      LOG_LEVEL = "debug";
      TZ = Timezone;
      PUID = PUID;
      PGID = PGID;
      PORT = "5055";
    };

    volumes = [
        "${ContainerPath}/seerr:/app/config"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.seerr.rule" = "Host(`seerr.${Domain}`)";
      "traefik.http.routers.seerr.entrypoints" = "websecure";
      "traefik.http.routers.seerr.tls" = "true";
      "traefik.http.routers.seerr.tls.certresolver" = "cloudflare";
      "traefik.http.services.seerr.loadbalancer.server.port" = "5055";
    };
  };

  systemd.services.docker-seerr = {
    after = [ "docker-create-proxy-network.service" "docker-traefik.service" ];
    requires = [ "docker-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
      "d ${ContainerPath}/seerr 0755 ${toString PUID} ${toString PGID}"
  ];
}
