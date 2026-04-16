{...}: {
  imports = [
    ./hardware-configuration.nix
    ./samba.nix
    ./podman.nix
    ../secrets.nix
  ];
}
