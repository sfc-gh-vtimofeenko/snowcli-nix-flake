{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs.follows = "nixpkgs-stable";

    snowflake-connector-python-1x = {
      url = "github:snowflakedb/snowflake-connector-python?ref=v3.2.0";
      flake = false;
    };
    snowflake-connector-python-2x = {
      url = "github:snowflakedb/snowflake-connector-python?ref=v3.6.0";
      flake = false;
    };

    /* Dependencies after this point are flake-development only, so feel free to stub them out */
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      imports = [
        inputs.devshell.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { config
        , pkgs
          /* These inputs are unused in the template, but might be useful later */
          # , self'
          # , inputs'
          # , system
        , ...
        }: {
          packages =
            let
              mkSnowpark = src: pkgs.callPackage ./packages/snowflake-connector-python/mkSnowflakeConnectorPython.nix { inherit (pkgs) python3; inherit src; };
            in
            {
              snowpark-for-snowcli-1x = mkSnowpark inputs.snowflake-connector-python-1x;
              snowpark-for-snowcli-2x = mkSnowpark inputs.snowflake-connector-python-2x;
            };
          /* Development configuration */
          treefmt = {
            programs = {
              nixpkgs-fmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
            projectRootFile = "flake.nix";
          };

          pre-commit.settings = {
            hooks.treefmt.enable = true;
            settings.treefmt.package = config.treefmt.build.wrapper;
          };

          devShells.pre-commit = config.pre-commit.devShell;
          devshells.default = {
            env = [ ];
            commands = [ ];
            packages = [
              config.pre-commit.settings.package
              config.treefmt.build.wrapper
            ];
          };
        };

      flake = { };
    };
}
