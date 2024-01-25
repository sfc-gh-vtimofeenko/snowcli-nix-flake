{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs.follows = "nixpkgs-stable";

    snowcli-src-1x = {
      url = "github:Snowflake-Labs/snowcli?ref=v1.2.4"; # Pins to last stable version tag by hand
      flake = false;
    };
    snowcli-src-2x = {
      url = "github:Snowflake-Labs/snowcli";
      flake = false;
    };
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

  outputs = inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      {
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

        imports = [
          inputs.flake-parts.flakeModules.easyOverlay

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
                mkSnowpark = { src, version }: pkgs.callPackage ./packages/snowflake-connector-python/mkSnowflakeConnectorPython.nix { inherit (pkgs) python3; inherit src version; };
                mkSnowcli = { src, version, snowflakeConnectorPkg }: pkgs.callPackage ./packages/snowcli/mkSnowcli.nix { inherit (pkgs) python3 lib; inherit src version snowflakeConnectorPkg; };

                snowpark-for-snowcli-1x = mkSnowpark { src = inputs.snowflake-connector-python-1x; version = "3.2.0"; };
                snowpark-for-snowcli-2x = mkSnowpark { src = inputs.snowflake-connector-python-2x; version = "3.6.0"; };
                snowcli-1x = mkSnowcli {
                  src = inputs.snowcli-src-1x;
                  version = "1.2.4";
                  snowflakeConnectorPkg = snowpark-for-snowcli-1x;
                };
                snowcli-2x = mkSnowcli {
                  src = inputs.snowcli-src-2x;
                  version = "2.0.0-dev";
                  snowflakeConnectorPkg = snowpark-for-snowcli-2x;
                };
              in
              {
                inherit snowpark-for-snowcli-1x snowpark-for-snowcli-2x snowcli-2x snowcli-1x;

                default = snowcli-2x;
              };
            overlayAttrs = builtins.removeAttrs config.packages [ "default" ];

            /* Development configuration */
            apps.renderHMDoc = import ./apps/renderHMDocs { inherit self pkgs; };
            treefmt = {
              programs = {
                nixpkgs-fmt.enable = true;
                deadnix = {
                  enable = true;
                  no-lambda-arg = true;
                  no-lambda-pattern-names = true;
                  no-underscore = true;
                };
                statix.enable = true;
              };
              projectRootFile = "flake.nix";
            };

            pre-commit.settings = {
              hooks = {
                treefmt.enable = true;
                deadnix.enable = true;
                statix.enable = true;
                mdsh.enable = true;
                mdsh.entry =
                  let
                    nixFlakeWrapper = pkgs.writeShellScriptBin "nix" "${pkgs.lib.getExe pkgs.nixFlakes} --extra-experimental-features nix-command --extra-experimental-features flakes $@";
                  in
                  pkgs.lib.mkForce (toString
                    (pkgs.writeShellScript "precommit-mdsh" ''
                      # This allows running nix commands in mdsh preprocessor inside nix flake check
                      export PATH=''${PATH}:${nixFlakeWrapper}/bin

                      for file in $(echo "$@"); do
                        ${config.pre-commit.settings.tools.mdsh}/bin/mdsh -i "$file"
                      done
                    ''));
              };
              settings = {
                deadnix.edit = true;
                statix = {
                  ignore = [ ".direnv/" ];
                  format = "stderr";
                };
                treefmt.package = config.treefmt.build.wrapper;
              };
            };

            devShells.pre-commit = config.pre-commit.devShell;
            devshells.default = {
              env = [ ];
              commands = [ ];
              packages = [
                config.pre-commit.settings.package
                config.treefmt.build.wrapper
                pkgs.mdsh
              ];
            };
          };

        /* Home manager module that configures snowcli */
        flake.homeManagerModules.default = flake-parts-lib.importApply ./modules/homeManager { localFlake = self; };

      }
    );
}

