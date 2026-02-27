{ pkgs, ... }:
{
  home.stateVersion = "24.11";
  programs.git.enable = true;
  home.packages = with pkgs; [
    vim
    tmux
    wget
  ];
}
