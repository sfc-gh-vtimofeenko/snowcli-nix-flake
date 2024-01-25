{ self, pkgs, ... }:
{
  type = "app";
  program =
    let
      eval = pkgs.lib.evalModules {
        modules = [
          self.homeManagerModules.default
          { _module.check = false; }
        ];
        specialArgs = { inherit pkgs; };
      };
      optionsDoc = pkgs.nixosOptionsDoc {
        inherit (eval) options;
        transformOptions = opt: if opt.name == "_module.args" then opt // { visible = false; } else opt // { declarations = [ ]; }; # TODO: restore file reference
      };
      moduleDoc = pkgs.runCommand "options-doc.md" { } ''
        cat ${optionsDoc.optionsCommonMark} >> $out
      '';
      showMd = pkgs.writeShellScriptBin "showMd" "${pkgs.coreutils}/bin/cat ${moduleDoc}";
    in
    showMd;
}
