{
  PUID,
  PGID,
  Timezone,
  ContainerPath,
  MediaPath,
  Domain,
  Hostname,
  ...
}: {
  virtualisation.oci-containers.containers.tdarr = {
    image = "ghcr.io/haveagitgat/tdarr:latest";
    autoStart = true;
    extraOptions = [
      "--memory=512m"
      "--cpus=1.0"
      "--device=/dev/dri/renderD128:/dev/dri/renderD128"
      "--network=proxy"
      "--security-opt=no-new-privileges:true"
    ];

    environment = {
      TZ = Timezone;
      PUID = PUID;
      PGID = PGID;
      UMASK_SET = "002";
      serverIP = "0.0.0.0";
      serverPort = "8266";
      webUIPort = "8265";
      internalNode = "true";
      inContainer = "true";
      ffmpegVersion = "7";
      nodeName = Hostname;
      auth = "false";
      openBrowser = "true";
      maxLogSizeMB = "10";
      cronPluginUpdate = "";
      enableDockerAutoUpdater = "false";
    };

    volumes = [
      "${ContainerPath}/tdarr/server:/app/server"
      "${ContainerPath}/tdarr/configs:/app/configs"
      "${ContainerPath}/tdarr/logs:/app/logs"
      "${MediaPath}:/media"
      "${ContainerPath}/tdarr/transcode_cache:/temp"
    ];

    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.tdarr.rule" = "Host(`tdarr.${Domain}`)";
      "traefik.http.routers.tdarr.entrypoints" = "websecure";
      "traefik.http.routers.tdarr.tls" = "true";
      "traefik.http.routers.tdarr.tls.certresolver" = "cloudflare";
      "traefik.http.services.tdarr.loadbalancer.server.port" = "8265";
    };
  };

  systemd.services.podman-tdarr = {
    after = ["podman-create-proxy-network.service" "podman-traefik.service"];
    requires = ["podman-create-proxy-network.service"];
  };

  systemd.tmpfiles.rules = [
    "d ${ContainerPath}/tdarr/configs 0755 ${toString PUID} ${toString PGID}"
    "d ${ContainerPath}/tdarr/logs 0755 ${toString PUID} ${toString PGID}"
    "d ${ContainerPath}/tdarr/transcode_cache 0755 ${toString PUID} ${toString PGID}"
    "d ${ContainerPath}/tdarr/server 0755 ${toString PUID} ${toString PGID}"
  ];
}

