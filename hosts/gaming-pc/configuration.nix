{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  networking.hostName = "gaming-pc";
  system.stateVersion = "24.11";
}
