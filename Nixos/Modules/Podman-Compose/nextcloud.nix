{ PUID, PGID, Timezone, ContainerPath, Hostname, nextcloudEnvFile, ... }: {
  virtualisation.oci-containers.containers.nextcloud-redis = {
    image = "redis:alpine";
    autoStart = true;
    extraOptions = [
      "--memory=192m"
      "--cpus=0.2"
      "--network=proxy"
      "--security-opt=no-new-privileges:true"
    ];

    environmentFiles = [ nextcloudEnvFile ];

    # Use shell form so we can expand REDIS_HOST_PASSWORD from the env file
    cmd = [
      "sh"
      "-c"
      ''exec redis-server --requirepass "$REDIS_HOST_PASSWORD"''
    ];

    volumes = [
      "${ContainerPath}/nextcloud/redis:/data"
    ];
  };

  virtualisation.oci-containers.containers.nextcloud = {
    image = "nextcloud:latest";
    autoStart = true;
    extraOptions = [
      "--memory=1280m"
      "--cpus=1.0"
      "--network=proxy"
      "--security-opt=no-new-privileges:true"
    ];

    environment = {
      PUID = PUID;
      PGID = PGID;
      TZ = Timezone;
      # SQLite is used by default when no DB env vars are set
      REDIS_HOST = "nextcloud-redis";
      REDIS_HOST_PORT = "6379";
      NEXTCLOUD_TRUSTED_DOMAINS = "localhost ${Hostname} 127.0.0.1";
    };

    environmentFiles = [ nextcloudEnvFile ];

    ports = [
      "8080:80"
    ];

    volumes = [
      "${ContainerPath}/nextcloud/html:/var/www/html"
    ];

    dependsOn = [ "nextcloud-redis" ];
  };

  systemd.services.podman-nextcloud-redis = {
    after = [ "podman-create-proxy-network.service" ];
    requires = [ "podman-create-proxy-network.service" ];
  };

  systemd.services.podman-nextcloud = {
    after = [ "podman-create-proxy-network.service" "podman-nextcloud-redis.service" ];
    requires = [ "podman-create-proxy-network.service" "podman-nextcloud-redis.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${ContainerPath}/nextcloud 0755 ${toString PUID} ${toString PGID}"
    "d ${ContainerPath}/nextcloud/html 0755 ${toString PUID} ${toString PGID}"
    "d ${ContainerPath}/nextcloud/redis 0755 ${toString PUID} ${toString PGID}"
  ];
}
