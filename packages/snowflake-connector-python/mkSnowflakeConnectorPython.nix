{ src
, python3
}:
python3.pkgs.snowflake-connector-python.overrideAttrs
  (
    _finalAttrs: previousAttrs: {
      inherit src;
      propagatedBuildInputs = previousAttrs.propagatedBuildInputs ++
        (builtins.attrValues { inherit (python3.pkgs) sortedcontainers packaging platformdirs tomlkit keyring; });
    }
  )
