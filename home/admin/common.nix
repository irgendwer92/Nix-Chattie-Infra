{ config, pkgs, ... }:
{
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "24.11";

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -lah";
      gs = "git status -sb";
      ga = "git add";
      gc = "git commit";
      k = "kubectl";
    };
    initExtra = ''
      export EDITOR=nvim
      export VISUAL=nvim
    '';
  };

  programs.git = {
    enable = true;
    userName = "Admin";
    userEmail = "admin@local";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      Host *
        ServerAliveInterval 30
        ServerAliveCountMax 5
    '';
  };

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

  home.packages = with pkgs; [
    rsync
    rclone
    unison
    ripgrep
    fd
    curl
    wget
    tmux
  ];
}
