{
  description = ":)";

  outputs = inputs@{self, nixpkgs-unstable, nixpkgs, home-manager, flake-utils, ...}: 
    let
      lib' = import ./lib {inherit self; lib = nixpkgs.lib;};
      lib = nixpkgs.lib.extend (
        final: prev: self.lib // home-manager.lib
      );
      overlays = (system: import ./pkgs/overlays {inherit inputs; inherit system; lib = lib; inherit self;});
      pkgs' = (system: import inputs.nixpkgs {
        system = system;
        overlays = (self.overlays.${system}.default);
        config = {
          allowBroken = true;
          allowUnfree = true;
          permittedInsecurePackages = [
          ];
        };
      });
      pkgs = pkgs' {system = system;} nixpkgs ((lib.attrValues overlays) ++ [
        (final: prev: {
          unstable = pkgs' system nixpkgs-unstable (lib.attrValues overlays);
        })
      ]);
    in
    {
    nixosConfigurations = let nixosSystem = {system ? "x86_64-linux", name}: (
        inputs.nixpkgs.lib.nixosSystem rec {
          inherit system;
          inherit lib;
          modules = [
            {
            nixpkgs.pkgs = pkgs;
            networking.hostName = lib.mkDefault name;
            }
            ./hosts/${name}
            ./modules
          ];
          specialArgs = {inherit inputs self;};
          }
        ); in {
      aakropotkin = nixosSystem { name = "aakropotkin"; };
    };

    lib = lib';

    } // 
    flake-utils.lib.eachDefaultSystem (system: 
      let 
        pkgs = pkgs' system nixpkgs (lib.attrValues overlays);
      in {
      overlays.default = overlays system;
      
      packages = let
        package = name: {${name} = import ./pkgs/derivations/${name} {inherit pkgs; lib = self.lib;};};
        in lib.attrListMerge (builtins.map package (lib.getSubDirNames ./pkgs/derivations));
    });  

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-utils={
      url = "github:numtide/flake-utils";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
