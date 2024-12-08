{
  description = "sway-ipc autolayout script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    janet-nix = {
      url = "github:turnerdev/janet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, janet-nix }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in
    {

      packages = forAllSystems (system: {
        default = janet-nix.packages.${system}.mkJanet {
          name = "autolayout";
          version = "0.0.1";
          src = ./.;
          quickbin = ./bin/autolayout.janet;
        };
      });
    };
}
