{ config, lib, pkgs, ... }:
let
  haUrl = "http://homeserver-laptop:8123";
in
{
  imports = [ ./common.nix ];

  services.syncthing.enable = lib.mkForce false;

  home.packages = with pkgs; [
    chromium
    wmctrl
  ];

  xdg.autostart.enable = true;
  xdg.desktopEntries.home-assistant-kiosk = {
    name = "Home Assistant Kiosk";
    exec = "${pkgs.chromium}/bin/chromium --kiosk --app=${haUrl} --noerrdialogs --disable-translate --check-for-update-interval=31536000";
    terminal = false;
    categories = [ "Network" "Utility" ];
  };

  xdg.configFile."autostart/home-assistant-kiosk.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Home Assistant Kiosk
    Exec=${pkgs.chromium}/bin/chromium --kiosk --app=${haUrl} --noerrdialogs --disable-session-crashed-bubble
    X-GNOME-Autostart-enabled=true
    X-KDE-autostart-phase=1
  '';
}
