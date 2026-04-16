{ PUID, PGID, Timezone, ContainerPath, Domain, piHoleEnvFile, ... }: {
  virtualisation.oci-containers.containers.pi-hole = {
    image = "pihole/pihole:latest";
    autoStart = true;

    ports = [
      "54:53/tcp"
      "54:53/udp"
    ];

    environment = {
      TZ = Timezone;
      PUID = PUID;
      PGID = PGID;
      FTLCONF_dns_listeningMode = "ALL";
    };

    environmentFiles = [ piHoleEnvFile ];

    volumes = [
      "${ContainerPath}/pi-hole:/etc/pihole"
    ];

    extraOptions = [
      "--memory=128m"
      "--cpus=0.2"
      "--network=proxy"
      "--security-opt=no-new-privileges:true"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.pi-hole.rule" = "Host(`pi-hole.${Domain}`)";
      "traefik.http.routers.pi-hole.entrypoints" = "websecure";
      "traefik.http.routers.pi-hole.tls" = "true";
      "traefik.http.routers.pi-hole.tls.certresolver" = "cloudflare";
      "traefik.http.services.pi-hole.loadbalancer.server.port" = "80";
    };
  };

  systemd.services.docker-pi-hole = {
    after = [ "docker-create-proxy-network.service" "docker-traefik.service" ];
    requires = [ "docker-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
      "d ${ContainerPath}/pi-hole/etc-pihole 0755 ${toString PUID} ${toString PGID}"
  ];
}
