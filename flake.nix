{
  description = "NixOS desktop configurations with single-disk btrfs and impermanence";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    aliases = {
      url = "github:tomuradjosip/aliases";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, impermanence, home-manager, plasma-manager, ... }@inputs:
    {
      nixosConfigurations = {
        # Office PC
        opg-office-pc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
            ./hosts/opg-office-pc
          ];
        };

        # Add more machines here:
        # another-pc = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     impermanence.nixosModules.impermanence
        #     ./hosts/another-pc
        #   ];
        # };
      };
    };
}
