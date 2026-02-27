{ ... }:
{
  disko.devices = {
    disk.system = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-system";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };

    disk.storage4tb = {
      type = "disk";
      device = "/dev/disk/by-id/ata-storage-4tb";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@data" = {
                  mountpoint = "/srv/storage/4tb/data";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@snapshots" = {
                  mountpoint = "/srv/storage/4tb/snapshots";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@backups" = {
                  mountpoint = "/srv/storage/4tb/backups";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };

    disk.storage8tb = {
      type = "disk";
      device = "/dev/disk/by-id/ata-storage-8tb";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@data" = {
                  mountpoint = "/srv/storage/8tb/data";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@snapshots" = {
                  mountpoint = "/srv/storage/8tb/snapshots";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@backups" = {
                  mountpoint = "/srv/storage/8tb/backups";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
