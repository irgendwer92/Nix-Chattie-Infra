{ config, lib, pkgs, ... }:
let
  inherit (lib) mkAfter mkIf;
  hostIsHomeserver = config.networking.hostName == "homeserver-laptop";
  dataRoot = "/srv/storage";
  appRoot = "${dataRoot}/8tb/data/apps";
  mediaRoot = "${dataRoot}/8tb/data/media";
in
{
  config = mkIf hostIsHomeserver {
    users.groups.media = { };
    users.groups.sambashare = { };
    users.users.admin.extraGroups = mkAfter [ "libvirtd" "docker" "media" "sambashare" ];


    services.btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "${dataRoot}/4tb/data" "${dataRoot}/8tb/data" ];
    };

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "homeserver-laptop";
          "map to guest" = "Bad User";
          "interfaces" = "lo enp* wlan*";
          "bind interfaces only" = "yes";
        };

        media = {
          path = mediaRoot;
          browseable = "yes";
          writable = "yes";
          "valid users" = "admin";
          "force group" = "media";
          "create mask" = "0664";
          "directory mask" = "2775";
        };

        backups = {
          path = "${dataRoot}/4tb/backups";
          browseable = "yes";
          writable = "yes";
          "valid users" = "admin";
        };

        apps = {
          path = appRoot;
          browseable = "yes";
          writable = "yes";
          "valid users" = "admin";
        };
      };
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
        ovmf.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      qemu_kvm
      virt-manager
      virt-viewer
      libguestfs
    ];

    systemd.tmpfiles.rules = [
      "d ${dataRoot}/4tb/data 0775 root media - -"
      "d ${dataRoot}/4tb/snapshots 0750 root root - -"
      "d ${dataRoot}/4tb/backups 0770 root sambashare - -"
      "d ${dataRoot}/8tb/data 0775 root media - -"
      "d ${dataRoot}/8tb/snapshots 0750 root root - -"
      "d ${dataRoot}/8tb/backups 0770 root sambashare - -"
      "d ${mediaRoot} 0775 root media - -"
      "d ${appRoot} 0770 root sambashare - -"
      "d ${appRoot}/traefik 0750 root root - -"
      "d ${appRoot}/paperless 0750 root root - -"
      "d ${appRoot}/paperless/data 0750 root root - -"
      "d ${appRoot}/paperless/media 0750 root media - -"
      "d ${appRoot}/paperless/export 0750 root media - -"
      "d ${appRoot}/paperless/consume 0750 root media - -"
      "d ${appRoot}/emby/config 0750 root media - -"
      "d ${appRoot}/transmission 0750 root root - -"
      "d ${appRoot}/heimdall/config 0750 root root - -"
      "d /var/lib/libvirt/images/homeassistant 0750 root root - -"
    ];

    virtualisation.docker.enable = true;


    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        traefik = {
          image = "traefik:v3.1";
          ports = [ "80:80" "443:443" "8080:8080" ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            "${appRoot}/traefik:/etc/traefik"
          ];
          extraOptions = [ "--network=host" ];
          cmd = [
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--entrypoints.web.address=:80"
            "--entrypoints.websecure.address=:443"
            "--api.dashboard=true"
          ];
        };

        paperless-broker = {
          image = "redis:7-alpine";
          ports = [ "6379:6379" ];
          extraOptions = [ "--network=host" ];
        };

        paperless-gotenberg = {
          image = "gotenberg/gotenberg:8";
          ports = [ "3000:3000" ];
          cmd = [ "gotenberg" "--chromium-disable-routes=true" ];
          extraOptions = [ "--network=host" ];
        };

        paperless-tika = {
          image = "ghcr.io/paperless-ngx/tika:latest";
          ports = [ "9998:9998" ];
          extraOptions = [ "--network=host" ];
        };

        paperless-ngx = {
          image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
          ports = [ "8010:8000" ];
          environment = {
            PAPERLESS_REDIS = "redis://127.0.0.1:6379";
            PAPERLESS_TIKA_ENABLED = "1";
            PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:9998";
            PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:3000";
            PAPERLESS_URL = "https://paperless.local";
          };
          environmentFiles = [ config.sops.templates."containers.env".path ];
          volumes = [
            "${appRoot}/paperless/data:/usr/src/paperless/data"
            "${appRoot}/paperless/media:/usr/src/paperless/media"
            "${appRoot}/paperless/export:/usr/src/paperless/export"
            "${appRoot}/paperless/consume:/usr/src/paperless/consume"
          ];
          extraOptions = [ "--network=host" "--label=traefik.enable=true" ];
          dependsOn = [ "paperless-broker" "paperless-gotenberg" "paperless-tika" ];
        };

        emby = {
          image = "lscr.io/linuxserver/emby:latest";
          ports = [ "8096:8096" "8920:8920" ];
          environment = {
            PUID = "0";
            PGID = "100";
            TZ = "Europe/Berlin";
          };
          volumes = [
            "${appRoot}/emby/config:/config"
            "${mediaRoot}:/media"
          ];
          extraOptions = [ "--network=host" ];
        };

        transmission-openvpn = {
          image = "haugene/transmission-openvpn:latest";
          ports = [ "9091:9091" ];
          environment = {
            OPENVPN_PROVIDER = "CUSTOM";
            OPENVPN_CONFIG = "custom";
            OPENVPN_USERNAME = config.sops.placeholder."vpn/openvpn-username";
            OPENVPN_PASSWORD = config.sops.placeholder."vpn/openvpn-password";
            LOCAL_NETWORK = "192.168.0.0/16";
            TRANSMISSION_WEB_UI = "flood-for-transmission";
          };
          volumes = [
            "${appRoot}/transmission:/data"
            "${appRoot}/transmission/config:/config"
          ];
          extraOptions = [
            "--network=host"
            "--cap-add=NET_ADMIN"
            "--device=/dev/net/tun"
          ];
        };

        heimdall = {
          image = "lscr.io/linuxserver/heimdall:latest";
          ports = [ "8082:80" ];
          environment = {
            PUID = "0";
            PGID = "100";
            TZ = "Europe/Berlin";
          };
          volumes = [ "${appRoot}/heimdall/config:/config" ];
          extraOptions = [ "--network=host" "--label=traefik.enable=true" ];
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkAfter [
      139
      445
      5357
      80
      443
      8080
      8010
      8096
      8920
      9091
      8082
    ];
    networking.firewall.allowedUDPPorts = mkAfter [ 137 138 3702 ];
  };
}
