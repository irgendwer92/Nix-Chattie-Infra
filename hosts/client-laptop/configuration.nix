{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  networking.hostName = "client-laptop";
  system.stateVersion = "24.11";
}
