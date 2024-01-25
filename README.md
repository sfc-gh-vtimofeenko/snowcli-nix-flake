This is a Nix flake that provides [snowcli](https://github.com/Snowflake-Labs/snowcli) and Snowpark python packages that are pinned to a more recent version than what's typically available in nixpkgs.

# Usage

Flake provides the `snowcli` packages and a `home-manager` module to configure snowcli in an environment.

Options to run snowcli from this flake:

* Without installing anything: `nix run github:sfc-gh-vtimofeenko/snowcli-nix-flake -- <SNOWCLI FLAGS>`
* Install the package in your configuration:
    1. Add this flake to the inputs
    2. Add `inputs.<snowcli_input_name>.packages.<architecture>.snowcli-2x` to your `environment.systemPackages`

       *- or -*

       add `inputs.<snowcli_input_name>.overlays.default` to your overlays list and add `pkgs.snowcli-2x` to `environment.systemPackages`
* Add and configure `home-manager` module by importing `inputs.<snowcli_input_name>.homeManagerModules.default` and [configuring the module](#home-manager-module-config)

## Home manager module config

Provided home manager module ([src](./modules/homeManager/default.nix)) allows configuring snowcli when it's installed in home-manager environment:

<!-- `> nix run .#renderHMDoc | sed 's;^##;###;'` -->
<!-- BEGIN mdsh -->
### programs\.snowcli\.enable

Whether to enable Snowcli\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `



### programs\.snowcli\.package



Package that provides Snowcli



*Type:*
package



*Default:*
` <derivation snowcli-2.0.0-dev> `



### programs\.snowcli\.settings



Snowcli configuration\.

*NOTE*: ` connection.dev ` is used as the default connection by Snowcli\.

See [doc](https://github\.com/Snowflake-Labs/snowcli) for more information\.



*Type:*
TOML value



*Example:*

```
{
  connections = {
    dev = {
      account = "account_identifier";
      authenticator = "externalbrowser";
      database = "some_database";
      user = "username";
    };
  };
}
```


<!-- END mdsh -->

## With .envrc

TODO

# Development

TODO
