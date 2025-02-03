{
	config,
	lib,
	pkgs,
	...
}: let
	cfg = config.programs.alejandra;
	tomlFormat = pkgs.formats.toml {};
in {
	meta.maintainers = [lib.hm.maintainers.vaisriv];

	options.programs.alejandra = {
		enable = lib.mkEnableOption "alejandra";

		package =
			mkOption {
				type = types.package;
				default = pkgs.alejandra;
				defaultText = literalExpression "pkgs.alejandra";
				description = ''
				  Alejandra package to install.
				'';
			};

		config =
			lib.mkOption {
				type = tomlFormat.type;
				default = {};
				example =
					lib.literalExpression ''
					  # (experimental) Configuration options for Alejandra

					  indentation = "Tabs" # Or: FourSpaces, Tabs
					'';
				description = ''
				  Configuration written to {file}`$XDG_CONFIG_HOME/alejandra/config.toml`.

				  See <https://github.com/kamadorueda/alejandra/blob/main/alejandra.toml> for
				  available options and documentation.
				'';
			};
	};

	config =
		lib.mkIf cfg.enable {
			home.packages = [cfg.package];

			xdg.configFile."alejandra/config.toml" =
				lib.mkIf (cfg.settings != {}) {
					source = tomlFormat.generate "config.toml" cfg.settings;
				};
		};
}
