{ python3
, src' ? null
, fetchFromGitHub
}:
import ./mkSnowflakeConnectorPython.nix {
  inherit python3;
  src =
    if builtins.isNull src' then
      fetchFromGitHub
        {
          owner = "snowflakedb";
          repo = "snowflake-connector-python";
          rev = "v3.2.0";
          hash = "sha256-gANSKnDyKXigr3buZlWETRZXvP4XOTBneRwE/RdSqEQ=";
        }
    else
      src';
}
