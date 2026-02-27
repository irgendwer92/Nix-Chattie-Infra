{ config, lib, sops-nix, ... }:
let
  inherit (lib) mkIf;
  serviceHosts = [ "homeserver-laptop" "vps" ];
  isServiceHost = builtins.elem config.networking.hostName serviceHosts;
in
{
  imports = [ sops-nix.nixosModules.sops ];

  config = mkIf isServiceHost {
    sops = {
      age = {
        keyFile = "/var/lib/sops-nix/key.txt";
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        generateKey = true;
      };

      defaultSopsFile = ../../../secrets/common.yaml;
      defaultSopsFormat = "yaml";

      secrets = {
        "smb/username" = { };
        "smb/password" = { };

        "containers/shared-env" = { };

        "vpn/openvpn-username" = { };
        "vpn/openvpn-password" = { };

        "apps/paperless-secret-key" = {
          sopsFile = ../../../secrets/homeserver.yaml;
        };
        "apps/traefik-api-token" = {
          sopsFile = ../../../secrets/vps.yaml;
        };
      };

      templates = {
        "containers.env" = {
          owner = "root";
          mode = "0400";
          content = ''
            SMB_USERNAME=${config.sops.placeholder."smb/username"}
            SMB_PASSWORD=${config.sops.placeholder."smb/password"}
            CONTAINERS_SHARED_ENV=${config.sops.placeholder."containers/shared-env"}
            PAPERLESS_SECRET_KEY=${config.sops.placeholder."apps/paperless-secret-key"}
            TRAEFIK_API_TOKEN=${config.sops.placeholder."apps/traefik-api-token"}
          '';
        };

        "openvpn-auth.txt" = {
          owner = "root";
          mode = "0400";
          content = ''
            ${config.sops.placeholder."vpn/openvpn-username"}
            ${config.sops.placeholder."vpn/openvpn-password"}
          '';
        };
      };
    };
  };
}
