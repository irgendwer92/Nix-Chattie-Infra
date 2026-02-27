{
  description = "Nix-Chattie-Infra with host-based NixOS flake structure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, disko, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      commonModules = [
        ./modules/nixos/networking.nix
        ./modules/nixos/ssh.nix
        ./modules/nixos/users.nix
        ./modules/nixos/monitoring-base.nix
        ./modules/nixos/secrets.nix
      ];

      hmProfiles = {
        client-laptop = ./home/admin/laptop.nix;
        tablet = ./home/admin/tablet.nix;
        gaming-pc = ./home/admin/gaming-pc.nix;
      };

      clientHosts = builtins.attrNames hmProfiles;

      mkHost = hostName:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self disko sops-nix;
          };
          modules =
            commonModules
            ++ [ ./hosts/${hostName}/configuration.nix ]
            ++ lib.optionals (builtins.elem hostName clientHosts) [
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.admin = import hmProfiles.${hostName};
              }
            ];
        };

      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        rpi5-klipper-1 = mkHost "rpi5-klipper-1";
        rpi5-klipper-2 = mkHost "rpi5-klipper-2";
        homeserver-laptop = mkHost "homeserver-laptop";
        vps = mkHost "vps";
        client-laptop = mkHost "client-laptop";
        tablet = mkHost "tablet";
        gaming-pc = mkHost "gaming-pc";
      };

      homeConfigurations = {
        "admin@client-laptop" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/admin/laptop.nix ];
        };
        "admin@tablet" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/admin/tablet.nix ];
        };
        "admin@gaming-pc" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/admin/gaming-pc.nix ];
        };
      };
    };
}
