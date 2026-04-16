{
  description = "My Homelab Flake!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs :
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        Harumi-Nixos = lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            ./Nixos/configuration.nix
          ];
        };
      };
      homeConfigurations = {
        harumi = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./Home/home.nix inputs.nvf.homeManagerModules.default ];
        };
      };
    };
}
