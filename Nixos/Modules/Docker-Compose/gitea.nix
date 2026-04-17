{ Timezone, PUID, PGID, Domain, ContainerPath, ... }: {
  virtualisation.oci-containers.containers.gitea = {
    image = "gitea/gitea:latest";
    autoStart = true;
    extraOptions = [
        "--memory=256m"
        "--cpus=0.4"
        "--network=proxy"
        "--security-opt=no-new-privileges:true"
      ];
    
    environment = {
      TZ = Timezone;
      PUID = PUID;
      PGID = PGID;
    };

    volumes = [
        "${ContainerPath}/gitea:/data"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.gitea.rule" = "Host(`gitea.${Domain}`)";
      "traefik.http.routers.gitea.entrypoints" = "websecure";
      "traefik.http.routers.gitea.tls" = "true";
      "traefik.http.routers.gitea.tls.certresolver" = "cloudflare";
      "traefik.http.services.gitea.loadbalancer.server.port" = "3000";
    };
  };

  systemd.services.docker-gitea = {
    after = [ "docker-create-proxy-network.service" "docker-traefik.service" ];
    requires = [ "docker-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
      "d ${ContainerPath}/gitea 0755 ${toString PUID} ${toString PGID}"
  ];
}
