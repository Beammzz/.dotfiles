{...}: {
  imports = [
    ./hardware-configuration.nix
    ./samba.nix
    ./docker.nix
    ../secrets.nix
  ];
}
