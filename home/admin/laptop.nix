{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  programs.bash.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake /workspace/Nix-Chattie-Infra#client-laptop";
  };

  services.syncthing = {
    enable = true;
    folders = {
      docs = {
        path = "/home/admin/Documents";
      };
    };
  };

  home.packages = with pkgs; [
    firefox
    thunderbird
    libreoffice
    keepassxc
    vlc
  ];
}
