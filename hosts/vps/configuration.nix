{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  networking.hostName = "vps";
  system.stateVersion = "24.11";

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}
