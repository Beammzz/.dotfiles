{ PUID, PGID, ContainerPath, beszelEnvFile, ... }: {
  virtualisation.oci-containers.containers.beszel = {
    image = "henrygd/beszel-agent-intel";
    autoStart = true;
    extraOptions = [
      "--memory=256m"
      "--cpus=0.4"
      "--network=host"
      "--cap-add=CAP_PERFMON"
      "--device=/dev/dri/card0:/dev/dri/card0"
      "--security-opt=no-new-privileges:true"
    ];

    volumes = [
      "/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${ContainerPath}/beszel_agent_data:/var/lib/beszel-agent"
    ];

    environment = {
      LISTEN = "45876";
    };

    environmentFiles = [ beszelEnvFile ];
  };

  systemd.services.podman-beszel = {
    after = [ "podman.service" "sops-install-secrets.service" ];
    requires = [ "podman.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${ContainerPath}/beszel_agent_data 0755 ${toString PUID} ${toString PGID}"
  ];
}
