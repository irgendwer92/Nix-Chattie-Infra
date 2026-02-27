{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  networking.hostName = "tablet";
  system.stateVersion = "24.11";
}
