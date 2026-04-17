{
  PUID,
  PGID,
  Email,
  Domain,
  ContainerPath,
  Timezone,
  traefikEnvFile,
  ...
}: {
  virtualisation.oci-containers.containers.traefik = {
    image = "traefik:3.6";
    autoStart = true;

    ports = [
      "80:80"
      "443:443"
    ];

    environment = {
      TZ = Timezone;
      PUID = PUID;
      PGID = PGID;
    };

    environmentFiles = [ traefikEnvFile ];

    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "${ContainerPath}/traefik/acme.json:/acme.json"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.traefik-dashboard.rule" = "Host(`traefik.${Domain}`)";
      "traefik.http.routers.traefik-dashboard.entrypoints" = "websecure";
      "traefik.http.routers.traefik-dashboard.service" = "api@internal";
      "traefik.http.routers.traefik-dashboard.tls" = "true";
      "traefik.http.routers.traefik-dashboard.tls.certresolver" = "cloudflare";
    };

    extraOptions = [
      "--memory=156m"
      "--cpus=0.4"
      "--network=proxy"
      "--security-opt=no-new-privileges:true"
    ];

    cmd = [
      # Global
      "--global.checkNewVersion=false"
      "--global.sendAnonymousUsage=false"

      # Logging
      "--log.level=INFO"

      # API & Dashboard
      "--api.dashboard=true"
      "--api.insecure=true"

      # Entrypoints
      "--entrypoints.web.address=:80"
      "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      "--entrypoints.websecure.address=:443"

      # Wildcard cert via Cloudflare DNS challenge
      "--entrypoints.websecure.http.tls=true"
      "--entrypoints.websecure.http.tls.certresolver=cloudflare"
      "--entrypoints.websecure.http.tls.domains[0].main=${Domain}"
      "--entrypoints.websecure.http.tls.domains[0].sans=*.${Domain}"

      # Docker provider
      "--providers.docker=true"
      "--providers.docker.endpoint=unix:///var/run/docker.sock"
      "--providers.docker.exposedbydefault=false"
      "--providers.docker.network=proxy"

      # Cloudflare ACME / Let's Encrypt
      "--certificatesresolvers.cloudflare.acme.email=${Email}"
      "--certificatesresolvers.cloudflare.acme.storage=/acme.json"
      "--certificatesresolvers.cloudflare.acme.dnschallenge=true"
      "--certificatesresolvers.cloudflare.acme.dnschallenge.provider=cloudflare"
      "--certificatesresolvers.cloudflare.acme.dnschallenge.resolvers=1.1.1.1:53,1.0.0.1:53"
    ];
  };

  systemd.services.docker-traefik = {
    after = [ "docker.service" "docker.socket" "docker-create-proxy-network.service" ];
    requires = [ "docker.service" "docker.socket" "docker-create-proxy-network.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${ContainerPath}/traefik 0750 ${PUID} ${PGID} -"
    "f ${ContainerPath}/traefik/acme.json 0600 ${PUID} ${PGID} -"
  ];
}
