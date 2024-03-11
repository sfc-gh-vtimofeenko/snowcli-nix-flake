{ python3
, src' ? null
, fetchFromGitHub
, callPackage
, lib
}:
let
  version = "2.1.0";
in
import ./mkSnowcli.nix {
  src =
    if builtins.isNull src' then
      fetchFromGitHub
        {
          owner = "Snowflake-Labs";
          repo = "snowcli";
          rev = "9b58d66e8138e12f06d1341a5407a8051ab1737c";
          hash = "sha256-B7kwbE9KRNcw3ZxX4ejKpuSqBuESw8l0Y4cWqvQwNC0=";
        }
    else
      src';
  inherit python3 version lib;
  snowflakeConnectorPkg = callPackage ../snowflake-connector-python/for-snowcli-2x.nix { inherit python3 fetchFromGitHub; };
}
