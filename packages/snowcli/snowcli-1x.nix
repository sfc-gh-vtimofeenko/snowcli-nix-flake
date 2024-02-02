{ python3
, src' ? null
, fetchFromGitHub
, callPackage
, lib
}:
let
  version = "1.2.4";
in
import ./mkSnowcli.nix {
  src =
    if builtins.isNull src' then
      fetchFromGitHub
        {
          owner = "Snowflake-Labs";
          repo = "snowcli";
          rev = "v${version}";
          hash = "sha256-ahUPDcf1Ql97IQSgalAUIZo2U2MiKxNPn0pKvDDQIu0=";
        }
    else
      src';
  inherit python3 version lib;
  snowflakeConnectorPkg = callPackage ../snowflake-connector-python/for-snowcli-1x.nix { inherit python3 fetchFromGitHub; };

}
