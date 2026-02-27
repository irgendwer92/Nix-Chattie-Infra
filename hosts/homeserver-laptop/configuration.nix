{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
    ../../modules/nixos/secrets/sops.nix
  ];

  networking.hostName = "homeserver-laptop";
  system.stateVersion = "24.11";
}
