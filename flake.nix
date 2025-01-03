{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.follows = "nixpkgs-unstable";

    # snowcli-src-1x = {
    #   url = "github:snowflakedb/snowflake-cli?ref=v1.2.4"; # Pins to last stable version tag by hand
    #   flake = false;
    # };

    snowcli-src-2x = {
      url = "github:snowflakedb/snowflake-cli?ref=v2.8.1"; # Pins to the latest 2.x version
      flake = false;
    };
    snowcli-src-live = {
      url = "github:snowflakedb/snowflake-cli"; # Follows the latest commit
      flake = false;
    };

    # snowflake-connector-python-1x = {
    #   url = "github:snowflakedb/snowflake-connector-python?ref=v3.2.0";
    #   flake = false;
    # };

    snowflake-connector-python-2x = {
      url = "github:snowflakedb/snowflake-connector-python?ref=v3.12.0";
      flake = false;
    };
    snowflake-connector-python-live = {
      url = "github:snowflakedb/snowflake-connector-python?ref=v3.12.0";
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
          , self'
            /* These inputs are unused in the template, but might be useful later */
          , inputs'
            # , system
          , ...
          }: {
            packages =
              let
                pkgs-unstable = inputs'.nixpkgs-unstable.legacyPackages;

                archiveNotice = "This repository has been archived since snowflake-cli is in nixpkgs";

                mkSnowflakeConnector = { src, version }: builtins.trace archiveNotice pkgs.callPackage ./packages/snowflake-connector-python/mkSnowflakeConnectorPython.nix { inherit (pkgs) python3; inherit src version; };
                mkSnowcli = { src, version, snowflakeConnectorPkg }: builtins.trace archiveNotice pkgs.callPackage ./packages/snowcli/mkSnowcli.nix { inherit (pkgs) python3 lib; inherit src version snowflakeConnectorPkg; };

                /**
                Function to create Snowpark connector package

                Compared to non-live version, it pins the packages to unstable
                */
                mkSnowflakeConnector-live = { src, version }:
                  let
                    pkgs = pkgs-unstable;
                  in
                  pkgs.callPackage ./packages/snowflake-connector-python/mkSnowflakeConnectorPython.nix { inherit (pkgs) python3; inherit src version; };

                /**
                Function to create snowcli package

                Compared to non-live version, it pins the packages to unstable
                */
                mkSnowcli-live = { src, version, snowflakeConnectorPkg }:
                  let
                    pkgs = pkgs-unstable;
                  in
                  pkgs.callPackage ./packages/snowcli/mkSnowcli.nix { inherit (pkgs) python3 lib; inherit src version snowflakeConnectorPkg; };

                # snowflake-connector-for-snowcli-1x = mkSnowflakeConnector { src = inputs.snowflake-connector-python-1x; version = "3.2.0"; };
                snowflake-connector-for-snowcli-2x = mkSnowflakeConnector { src = inputs.snowflake-connector-python-2x; version = "3.12.0"; };
                snowflake-connector-for-snowcli-live = mkSnowflakeConnector-live { src = inputs.snowflake-connector-python-live; version = "3.12.0"; };

                # snowcli-1x = mkSnowcli {
                #   src = inputs.snowcli-src-1x;
                #   version = "1.2.4";
                #   snowflakeConnectorPkg = snowflake-connector-for-snowcli-1x;
                # };
                snowcli-2x = mkSnowcli {
                  src = inputs.snowcli-src-2x;
                  version = "2.8.1";
                  snowflakeConnectorPkg = snowflake-connector-for-snowcli-2x;
                };
                snowcli-live = mkSnowcli-live {
                  src = inputs.snowcli-src-live;
                  version = "3.x-live";
                  snowflakeConnectorPkg = snowflake-connector-for-snowcli-live;
                };
              in
              rec {
                inherit snowflake-connector-for-snowcli-2x snowflake-connector-for-snowcli-live snowcli-2x snowcli-live;

                default = snowcli-3x;

                snowcli-3x = pkgs-unstable.callPackage ./packages/snowcli/snowcli-3x.nix { };
                snowcli-3x-rc = pkgs-unstable.callPackage ./packages/snowcli/snowcli-3x-rc.nix { };
              };
            overlayAttrs = builtins.removeAttrs config.packages [ "default" ];

            checks =
              let
                mkPkgForceCheck = pkg: pkg.overridePythonAttrs (_: { doCheck = true; });
              in
              {
                "check-version-works" = pkgs.runCommand "check-version-works" { } ''
                  ${pkgs.lib.getExe self'.packages.default} --version || (echo "Version did not exit successfully" && exit 1)
                  # Derivation has to produce _some_ output
                  mkdir $out
                '';

                # Snowcli checks are kinda slow. Better run it once by CI when pushing this flake out than to eval them every time it's installed
                run-snowcli-3x-check = mkPkgForceCheck self'.packages.snowcli-3x;
                run-snowcli-3x-rc-check = mkPkgForceCheck self'.packages.snowcli-3x-rc;
              };

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
                treefmt = {
                  enable = true;
                  package = config.treefmt.build.wrapper;
                };
                deadnix = {
                  enable = true;
                  settings.edit = true;
                };
                statix = {
                  enable = true;
                  settings = {
                    ignore = [ ".direnv/" ];
                    format = "stderr";
                  };
                };
                yamllint.enable = true;
              };
            };

            devShells.pre-commit = config.pre-commit.devShell;
            devshells.default = {
              env = [ ];
              commands = [ ];
              packages = [
                config.pre-commit.settings.package
                config.treefmt.build.wrapper
                config.pre-commit.settings.tools.mdsh
              ];
            };
          };

        /* Home manager module that configures snowcli */
        flake.homeManagerModules.default = flake-parts-lib.importApply ./modules/homeManager { localFlake = self; };

      }
    );
}

