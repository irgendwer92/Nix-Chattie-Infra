{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
    ../../modules/nixos/roles/homeserver.nix
  ];

  networking.hostName = "homeserver-laptop";
  system.stateVersion = "24.11";
}
