{ Timezone, PUID, PGID, Domain, ContainerPath, MediaPath, homepageEnvFile, ... }:
{
  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
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
      HOMEPAGE_ALLOWED_HOSTS = "homepage.${Domain}";
    };

    environmentFiles = [ homepageEnvFile ];

    volumes = [
        "${toString ../../../Homepage/config}:/app/config"
        "${toString ../../../Homepage/images}:/app/public/images"
        "${MediaPath}:/mnt/media:ro"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.homepage.rule" = "Host(`homepage.${Domain}`)";
      "traefik.http.routers.homepage.entrypoints" = "websecure";
      "traefik.http.routers.homepage.tls" = "true";
      "traefik.http.routers.homepage.tls.certresolver" = "cloudflare";
      "traefik.http.services.homepage.loadbalancer.server.port" = "3000";
    };
  };

  systemd.services.docker-homepage = {
    after = [ "docker.service" "docker-create-proxy-network.service" "docker-traefik.service" ];
    requires = [ "docker.service" "docker-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
      "d ${toString ../../../Homepage/config} 0755 ${toString PUID} ${toString PGID}"
      "d ${toString ../../../Homepage/images} 0755 ${toString PUID} ${toString PGID}"
  ];
}