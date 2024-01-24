{ python3
, src' ? null
, fetchFromGitHub
}:
let
  version = "3.2.0";
in
import ./mkSnowflakeConnectorPython.nix {
  inherit python3 version;
  src =
    if builtins.isNull src' then
      fetchFromGitHub
        {
          owner = "snowflakedb";
          repo = "snowflake-connector-python";
          rev = "v${version}";
          hash = "sha256-gANSKnDyKXigr3buZlWETRZXvP4XOTBneRwE/RdSqEQ=";
        }
    else
      src';
}
