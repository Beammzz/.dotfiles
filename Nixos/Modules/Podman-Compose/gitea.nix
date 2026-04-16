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

  systemd.services.podman-gitea = {
    after = [ "podman-create-proxy-network.service" "podman-traefik.service" ];
    requires = [ "podman-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
      "d ${ContainerPath}/gitea 0755 ${toString PUID} ${toString PGID}"
  ];
}
