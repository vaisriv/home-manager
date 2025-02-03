{ config, lib, pkgs, ... }:

let

  cfg = config.programs.alejandra ;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ lib.hm.maintainers.vaisriv ];

  options.programs.alejandra = {
    enable = lib.mkEnableOption "alejandra";

    package = lib.mkPackageOption pkgs "alejandra" { };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          note = {
            language = "en";
            default-title = "Untitled";
            filename = "{{id}}-{{slug title}}";
            extension = "md";
            template = "default.md";
            id-charset = "alphanum";
            id-length = 4;
            id-case = "lower";
          };
          extra = {
            author = "Mickaël";
          };
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/alejandra/config.toml`.

        See <https://github.com/mickael-menu/alejandra/blob/main/docs/config.md> for
        available options and documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."alejandra/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
