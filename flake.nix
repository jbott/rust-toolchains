{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    fenix,
    flake-utils,
    nixpkgs,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      # Get nixpkgs
      pkgs = import nixpkgs {inherit system;};
      inherit (pkgs) lib;

      # Get fenix packages, and construct a helper that lets us construct a toolchain derivation
      fenixPkgs = fenix.packages.${system};
      mkToolchain = target:
        fenixPkgs.combine (with fenixPkgs; [
          minimal.rustc
          minimal.cargo
          targets.${target}.latest.rust-std
        ]);

      # Construct a shell for a toolchain derivation
      mkToolchainShell = target:
        pkgs.mkShell {
          name = "rust-toolchain-${target}";
          buildInputs = [(mkToolchain target)];
        };

      # All targets we want to support
      allTargets = [
        "aarch64-apple-darwin"
        "aarch64-unknown-linux-gnu"
        "thumbv7em-none-eabihf"
        "x86_64-apple-darwin"
        "x86_64-unknown-linux-gnu"
      ];
    in {
      formatter = pkgs.alejandra;
      # nix shell .#{target}
      packages = lib.attrsets.genAttrs allTargets mkToolchain;
      # nix develop .#{target}
      devShells = lib.attrsets.genAttrs allTargets mkToolchainShell;
    });
}
