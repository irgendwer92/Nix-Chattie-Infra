{ disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
    ../../modules/nixos/roles/homeserver.nix
  ];

  networking.hostName = "homeserver-laptop";
  system.stateVersion = "24.11";

  # Bestehende Datenplatten: nur mounten, nicht formatieren.
  # IDs ggf. an echte Werte unter /dev/disk/by-id anpassen.
  fileSystems = {
    "/srv/storage/8tb" = {
      device = "/dev/disk/by-id/ata-storage-8tb";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "nofail" ];
    };

    "/srv/storage/12tb-a" = {
      device = "/dev/disk/by-id/ata-storage-12tb-a";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "nofail" ];
    };

    "/srv/storage/12tb-b" = {
      device = "/dev/disk/by-id/ata-storage-12tb-b";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "nofail" ];
    };

    # Die 5TB-Spiegelplatten laufen direkt auf den Blockdevices (z. B. /dev/sdX, nicht /dev/sdX1).
    "/srv/storage/mirror5tb" = {
      device = "/dev/disk/by-id/ata-storage-5tb-a";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "noatime"
        "nofail"
        "degraded"
        "device=/dev/disk/by-id/ata-storage-5tb-b"
      ];
    };
  };
}
