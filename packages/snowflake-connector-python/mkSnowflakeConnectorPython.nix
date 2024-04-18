{ src
, python3
, version
}:
python3.pkgs.snowflake-connector-python.overrideAttrs (
  _finalAttrs: previousAttrs: {
    inherit src version;
    name = "snowflake-connector-python-${version}";
    propagatedBuildInputs =
      previousAttrs.propagatedBuildInputs
      ++ (builtins.attrValues {
        inherit (python3.pkgs)
          sortedcontainers
          packaging
          platformdirs
          tomlkit
          keyring
          pythonRelaxDepsHook
          ;
      });
    pythonRelaxDeps = true;
  }
)
