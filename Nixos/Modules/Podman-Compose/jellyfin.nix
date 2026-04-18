{ PUID, PGID, Timezone, ContainerPath, MediaPath, ... }: {
  virtualisation.oci-containers.containers.jellyfin = {
    image = "jellyfin/jellyfin:latest";
    autoStart = true;
    extraOptions = [
        "--memory=512m"
        "--cpus=1.0"
        "--network=proxy"
        "--security-opt=no-new-privileges:true"
        "--group-add=303"
        "--device=/dev/dri/renderD128:/dev/dri/renderD128"
    ];

    environment = {
      TZ = Timezone;
      PUID = PUID;
      PGID = PGID;
    };

    ports = [
      "8096:8096"
    ];

    volumes = [
        "${ContainerPath}/jellyfin/config:/config"
        "${MediaPath}:/media"
    ];
  };

  systemd.services.docker-jellyfin = {
    after = [ "docker-create-proxy-network.service" "docker-traefik.service" ];
    requires = [ "docker-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
      "d ${ContainerPath}/jellyfin 0755 ${toString PUID} ${toString PGID}"
      "d ${ContainerPath}/jellyfin/config 0755 ${toString PUID} ${toString PGID}"
  ];
}
