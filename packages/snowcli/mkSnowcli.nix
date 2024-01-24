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

  nativeBuildInputs = builtins.attrValues { inherit (python3.pkgs) hatch-vcs hatchling; };

  propagatedBuildInputs = builtins.attrValues
    {
      inherit (python3.pkgs)
        coverage
        jinja2
        rich
        requests
        requirements-parser
        strictyaml
        tomlkit
        typer
        chardet# needed by snowflake-connector-python
        urllib3
        gitpython
        pluggy
        pyyaml
        pythonRelaxDepsHook
        ;
    }
  ++ [ snowflakeConnectorPkg ]; /* Pass specific version of snowflake connector */

  pythonRelaxDeps = [
    "coverage"
    "jinja2"
    "pluggy"
    "PyYAML"
    "rich"
    "requests"
    "requirements-parser"
    "snowflake-connector-python"
    "strictyaml"
    "tomlkit"
    "typer"
    "urllib3"
    "GitPython"
  ];
}
