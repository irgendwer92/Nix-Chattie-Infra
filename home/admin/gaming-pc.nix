{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  programs.bash.shellAliases = {
    gamemode-on = "systemctl --user start gamemoded.service";
  };

  home.packages = with pkgs; [
    mangohud
    lutris
    heroic
    prismlauncher
    gamescope
    gamemode
    goverlay
  ];

  xdg.configFile."MangoHud/MangoHud.conf".text = ''
    fps_limit=165
    frame_timing=1
    position=top-left
    cpu_stats=1
    gpu_stats=1
    ram
    vram
  '';

  xdg.configFile."gamemode.ini".text = ''
    [general]
    desiredgov=performance
    renice=10
    softrealtime=auto
  '';
}
