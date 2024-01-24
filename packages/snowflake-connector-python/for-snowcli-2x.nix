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
          rev = "v3.6.0";
          hash = "sha256-QBer3ESJW7w+PJvB/5Nl/rWgS0HwCq0m5Dp3t/1Fb04=";
        }
    else
      src';
}
