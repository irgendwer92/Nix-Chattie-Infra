{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
    ../../modules/nixos/secrets/sops.nix
  ];

  networking.hostName = "vps";
  system.stateVersion = "24.11";

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}
