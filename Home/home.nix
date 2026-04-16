{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./Modules/modules.nix
  ];

  home.username = "harumi";
  home.homeDirectory = "/home/harumi";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    fastfetch
    btop
  ];

  home.file = {
    ".p10k.zsh" = {
      source = ./.p10k.zsh;
      executable = true;
    };
  };

  home.sessionVariables = {
  };

  # Enable Programs
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "Harumi";
        user.email = "Sorrathon@proton.me";
      };
    };
  };

  # Enable Home Manager
  programs.home-manager.enable = true;
}
