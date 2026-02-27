{ config, lib, sops-nix, ... }:
let
  inherit (lib) mkIf;
  serviceHosts = [ "homeserver-laptop" "vps" ];
  isServiceHost = builtins.elem config.networking.hostName serviceHosts;
  privateSecretsDir = ../../../secrets/private;
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

      defaultSopsFile = privateSecretsDir + "/common.yaml";
      defaultSopsFormat = "yaml";

      secrets = {
        "smb/username".path = "/run/secrets/smb-username";
        "smb/password".path = "/run/secrets/smb-password";

        "containers/shared-env".path = "/run/secrets/containers-shared-env";

        "vpn/openvpn-username".path = "/run/secrets/openvpn-username";
        "vpn/openvpn-password".path = "/run/secrets/openvpn-password";

        "apps/paperless-secret-key" = {
          sopsFile = privateSecretsDir + "/homeserver-laptop.yaml";
          path = "/run/secrets/paperless-secret-key";
        };

        "apps/traefik-api-token" = {
          sopsFile = privateSecretsDir + "/vps.yaml";
          path = "/run/secrets/traefik-api-token";
        };
      };

      templates = {
        "containers.env" = {
          owner = "root";
          mode = "0400";
          path = "/run/secrets/containers.env";
          content = ''
            SMB_USERNAME=${config.sops.placeholder."smb/username"}
            SMB_PASSWORD=${config.sops.placeholder."smb/password"}
            CONTAINERS_SHARED_ENV=${config.sops.placeholder."containers/shared-env"}
            PAPERLESS_SECRET_KEY=${config.sops.placeholder."apps/paperless-secret-key"}
            TRAEFIK_API_TOKEN=${config.sops.placeholder."apps/traefik-api-token"}
          '';
        };

        "openvpn.env" = {
          owner = "root";
          mode = "0400";
          path = "/run/secrets/openvpn.env";
          content = ''
            OPENVPN_USERNAME=${config.sops.placeholder."vpn/openvpn-username"}
            OPENVPN_PASSWORD=${config.sops.placeholder."vpn/openvpn-password"}
          '';
        };

        "openvpn-auth.txt" = {
          owner = "root";
          mode = "0400";
          path = "/run/secrets/openvpn-auth.txt";
          content = ''
            ${config.sops.placeholder."vpn/openvpn-username"}
            ${config.sops.placeholder."vpn/openvpn-password"}
          '';
        };
      };
    };
  };
}
