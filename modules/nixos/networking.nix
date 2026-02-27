{ lib, ... }:
{
  networking.useNetworkd = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault false;
  networking.firewall = {
    enable = lib.mkDefault true;
    allowedTCPPorts = [ 22 ];
  };
  time.timeZone = lib.mkDefault "Europe/Berlin";
}
