{ ... }:
{
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChangeMeReplaceWithYourKey admin@nix-chattie"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
