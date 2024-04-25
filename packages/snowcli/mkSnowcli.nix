{ src
, python3
, snowflakeConnectorPkg
, version
, lib
}:
python3.pkgs.buildPythonApplication {
  pname = "snowcli";
  inherit version src;
  format = "pyproject";
  meta = {
    mainProgram = "snow";
    description = "Snowflake CLI";
    homepage = "https://github.com/Snowflake-Labs/snowcli";
    license = lib.licenses.asl20;
  };

  nativeBuildInputs = builtins.attrValues { inherit (python3.pkgs) hatch-vcs hatchling pythonRelaxDepsHook; };

  propagatedBuildInputs = builtins.attrValues
    {
      inherit (python3.pkgs)
        jinja2
        pluggy
        pyyaml
        rich
        requests
        requirements-parser
        setuptools
        tomlkit
        typer
        urllib3
        chardet# needed by snowflake-connector-python
        gitpython
        pydantic
        ;
    }
  ++ [ snowflakeConnectorPkg ]; /* Pass specific version of snowflake connector */

  pythonRelaxDeps = true;
  dontCheckRuntimeDeps = true;
}
