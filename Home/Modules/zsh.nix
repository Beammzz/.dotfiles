{ ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      update = "~/.dotfiles/Scripts/update.sh";
      clean = "~/.dotfiles/Scripts/clean.sh";
    };
    history.size = 10000;
    zplug = {
      enable = true;
      plugins = [
        {name = "zsh-users/zsh-autosuggestions";}
        {
          name = "romkatv/powerlevel10k";
          tags = ["as:theme" "depth:1"];
        }
      ];
    };

    initContent = "
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    ";
  };
}