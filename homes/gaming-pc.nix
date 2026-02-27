{ pkgs, ... }:
{
  imports = [ ./common.nix ];
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.packages = with pkgs; [
    mangohud
    lutris
  ];
}
