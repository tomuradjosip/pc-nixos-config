{
  description = "NixOS desktop configurations with single-disk btrfs and impermanence";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
    aliases = {
      url = "github:tomuradjosip/aliases";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, impermanence, ... }@inputs:
    {
      nixosConfigurations = {
        # Office PC
        opg-office-pc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            impermanence.nixosModules.impermanence
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
