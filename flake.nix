{
  description = "Nix-Chattie-Infra with host-based NixOS flake structure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      commonModules = [
        ./modules/nixos/networking.nix
        ./modules/nixos/ssh.nix
        ./modules/nixos/users.nix
        ./modules/nixos/monitoring-base.nix
      ];

      clientHosts = [ "client-laptop" "tablet" "gaming-pc" ];

      mkHost = hostName:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self disko;
          };
          modules =
            commonModules
            ++ [ ./hosts/${hostName}/configuration.nix ]
            ++ lib.optionals (builtins.elem hostName clientHosts) [
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.admin = import ./homes/${hostName}.nix;
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
          modules = [ ./homes/client-laptop.nix ];
        };
        "admin@tablet" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./homes/tablet.nix ];
        };
        "admin@gaming-pc" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./homes/gaming-pc.nix ];
        };
      };
    };
}
