{
  description = "Description for the project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs.follows = "nixpkgs-stable";

    snowcli-src-1x = {
      url = "github:snowflakedb/snowflake-cli?ref=v1.2.4"; # Pins to last stable version tag by hand
      flake = false;
    };
    snowcli-src-2x = {
      url = "github:snowflakedb/snowflake-cli?ref=v2.1.0"; # Pins to the latest 2.x version
      flake = false;
    };
    snowflake-connector-python-1x = {
      url = "github:snowflakedb/snowflake-connector-python?ref=v3.2.0";
      flake = false;
    };
    snowflake-connector-python-2x = {
      url = "github:snowflakedb/snowflake-connector-python?ref=v3.7.0";
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
            # , inputs'
            # , system
          , ...
          }: {
            packages =
              let
                mkSnowflakeConnector = { src, version }: pkgs.callPackage ./packages/snowflake-connector-python/mkSnowflakeConnectorPython.nix { inherit (pkgs) python3; inherit src version; };
                mkSnowcli = { src, version, snowflakeConnectorPkg }: pkgs.callPackage ./packages/snowcli/mkSnowcli.nix { inherit (pkgs) python3 lib; inherit src version snowflakeConnectorPkg; };

                snowflake-connector-for-snowcli-1x = mkSnowflakeConnector { src = inputs.snowflake-connector-python-1x; version = "3.2.0"; };
                snowflake-connector-for-snowcli-2x = mkSnowflakeConnector { src = inputs.snowflake-connector-python-2x; version = "3.7.0"; };
                snowcli-1x = mkSnowcli {
                  src = inputs.snowcli-src-1x;
                  version = "1.2.4";
                  snowflakeConnectorPkg = snowflake-connector-for-snowcli-1x;
                };
                snowcli-2x = mkSnowcli {
                  src = inputs.snowcli-src-2x;
                  version = "2.1.0";
                  snowflakeConnectorPkg = snowflake-connector-for-snowcli-2x;
                };
              in
              {
                inherit snowflake-connector-for-snowcli-1x snowflake-connector-for-snowcli-2x snowcli-2x snowcli-1x;

                default = snowcli-2x;
              };
            overlayAttrs = builtins.removeAttrs config.packages [ "default" ];

            checks."check-version-works" =
              if pkgs.stdenv.isLinux then
                pkgs.testers.runNixOSTest
                  {
                    name = "check-version-output";

                    nodes.machine1 = {
                      environment.systemPackages = [ self'.packages.snowcli-2x ];
                    };

                    testScript =
                      # python
                      ''
                        start_all()

                        command, exit_code = "snow --version", 0

                        assert machine1.execute(command)[0] == exit_code, f"'{command}' did not exit with code {exit_code}"
                      '';

                  } else pkgs.hello;

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
                yamllint.enable = true;
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
                config.pre-commit.settings.tools.mdsh
              ];
            };
          };

        /* Home manager module that configures snowcli */
        flake.homeManagerModules.default = flake-parts-lib.importApply ./modules/homeManager { localFlake = self; };

      }
    );
}

