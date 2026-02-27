{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ htop iotop ];

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    port = 9100;
    openFirewall = true;
  };
}
