/* Home manager module for snowcli */
{ localFlake }:
{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf;
  inherit (pkgs.stdenv.hostPlatform) system isDarwin;

  cfg = config.programs.snowcli;
  selfPkgs' = localFlake.packages.${system};
  settingsFormat = pkgs.formats.toml { };

  /* Depending on the platform, the config should be in a different location */
  configFile = (if isDarwin then "Library/Application Support" else config.xdg.configHome) + "/snowflake/config.toml";
in
{
  options.programs.snowcli = {
    enable = mkEnableOption "Snowcli";
    package = mkOption {
      type = types.package;
      inherit (selfPkgs') default;
      description = lib.mdDoc "Package that provides Snowcli";
    };
    settings = lib.mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
      };
      example = {
        connections.default = {
          account = "account_identifier";
          user = "username";
          database = "some_database";
          authenticator = "externalbrowser";
        };
      };
      description = lib.mdDoc ''
        Snowcli configuration.

        This value is copied to the Nix store in plaintext, so consider using env variables for secrets.

        *NOTE*: `connection.default` is used as the default connection by Snowcli.

        See [doc](https://github.com/Snowflake-Labs/snowcli) for more information.
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file.${configFile}.source = settingsFormat.generate "config.toml" cfg.settings;
  };
}

