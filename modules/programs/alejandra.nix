{ config, lib, pkgs, ... }:

with lib;

{
  imports = let
    msg = ''
      'programs.alejandra.enableAliases' has been deprecated and replaced with integration
      options per shell, for example, 'programs.alejandra.enableBashIntegration'.

      Note, the default for these options is 'true' so if you want to enable the
      aliases you can simply remove 'programs.alejandra.enableAliases' from your
      configuration.'';
    mkRenamed = opt:
      mkRenamedOptionModule [ "programs" "exa" opt ] [ "programs" "alejandra" opt ];
  in (map mkRenamed [ "enable" "extraOptions" "icons" "git" ])
  ++ [ (mkRemovedOptionModule [ "programs" "alejandra" "enableAliases" ] msg) ];

  meta.maintainers = [ maintainers.cafkafk ];

  options.programs.alejandra = {
    enable = mkEnableOption "alejandra, a modern replacement for {command}`ls`";

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };

    enableIonIntegration = mkEnableOption "Ion integration" // {
      default = true;
    };

    enableNushellIntegration = mkEnableOption "Nushell integration";

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--group-directories-first" "--header" ];
      description = ''
        Extra command line options passed to alejandra.
      '';
    };

    icons = mkOption {
      type = types.enum [ null true false "auto" "always" "never" ];
      default = null;
      description = ''
        Display icons next to file names ({option}`--icons` argument).

        Note, the support for Boolean values is deprecated.
        Setting this option to `true` corresponds to `--icons=auto`.
      '';
    };

    colors = mkOption {
      type = types.enum [ null "auto" "always" "never" ];
      default = null;
      description = ''
        Use terminal colors in output ({option}`--color` argument).
      '';
    };

    git = mkOption {
      type = types.bool;
      default = false;
      description = ''
        List each file's Git status if tracked or ignored ({option}`--git` argument).
      '';
    };

    package = mkPackageOption pkgs "alejandra" { };
  };

  config = let
    cfg = config.programs.alejandra;

    iconsOption = let
      v = if isBool cfg.icons then
        (if cfg.icons then "auto" else null)
      else
        cfg.icons;
    in optionals (v != null) [ "--icons" v ];

    args = escapeShellArgs (iconsOption
      ++ optionals (cfg.colors != null) [ "--color" cfg.colors ]
      ++ optional cfg.git "--git" ++ cfg.extraOptions);

    optionsAlias = optionalAttrs (args != "") { alejandra = "alejandra ${args}"; };

    aliases = builtins.mapAttrs (_name: value: lib.mkDefault value) {
      ls = "alejandra";
      ll = "alejandra -l";
      la = "alejandra -a";
      lt = "alejandra --tree";
      lla = "alejandra -la";
    };
  in mkIf cfg.enable {
    warnings = optional (isBool cfg.icons) ''
      Setting programs.alejandra.icons to a Boolean is deprecated.
      Please update your configuration so that

        programs.alejandra.icons = ${if cfg.icons then ''"auto"'' else "null"}'';

    home.packages = [ cfg.package ];

    programs.bash.shellAliases = optionsAlias
      // optionalAttrs cfg.enableBashIntegration aliases;

    programs.zsh.shellAliases = optionsAlias
      // optionalAttrs cfg.enableZshIntegration aliases;

    programs.fish = mkMerge [
      (mkIf (!config.programs.fish.preferAbbrs) {
        shellAliases = optionsAlias
          // optionalAttrs cfg.enableFishIntegration aliases;
      })

      (mkIf config.programs.fish.preferAbbrs {
        shellAliases = optionsAlias;
        shellAbbrs = optionalAttrs cfg.enableFishIntegration aliases;
      })
    ];

    programs.ion.shellAliases = optionsAlias
      // optionalAttrs cfg.enableIonIntegration aliases;

    programs.nushell.shellAliases = optionsAlias
      // optionalAttrs cfg.enableNushellIntegration aliases;
  };
}
