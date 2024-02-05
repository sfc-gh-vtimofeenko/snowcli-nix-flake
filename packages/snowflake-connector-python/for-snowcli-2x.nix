{ python3
, src' ? null
, fetchFromGitHub
}:
let
  version = "3.7.0";
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
          hash = "sha256-QBer3ESJW7w+PJvB/5Nl/rWgS0HwCq0m5Dp3t/1Fb04=";
        }
    else
      src';
}
