{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}:

{
  # Enable zsh system-wide
  programs.zsh = {
    enable = true;

    shellInit = ''
      # Set aliases directory for help function
      export ALIASES_DIR="${inputs.aliases}"
      export NIXOS_FLAKE="$HOME/pc-nixos-config"

      # Source shared aliases from GitHub repo
      source ${inputs.aliases}/core.zsh
      source ${inputs.aliases}/git.zsh
      source ${inputs.aliases}/nixos.zsh
      source ${inputs.aliases}/help.zsh

      # Initialize oh-my-posh with custom theme
      eval "$(oh-my-posh init zsh --config $HOME/pc-nixos-config/themes/terminal_theme.json)"
    '';

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "history"
        "colored-man-pages"
        "zsh-interactive-cd"
        "zsh-navigation-tools"
      ];
    };

    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
  };
}
