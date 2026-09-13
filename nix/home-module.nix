{
  configDir,
  quickshellPackages,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.quickshell-config;
  system = pkgs.stdenv.hostPlatform.system;
  defaultPackage = quickshellPackages.${system}.default or pkgs.quickshell;
in
{
  _class = "homeManager";

  options.programs.quickshell-config = {
    enable = lib.mkEnableOption "the quickshell configuration from this flake";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "inputs.quickshell.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "The quickshell package to use.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "quickshell-config";
      description = "Name of the quickshell configuration to install.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start quickshell automatically with the user's graphical session.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      package = cfg.package;
      configs.${cfg.configName} = configDir;
      activeConfig = cfg.configName;
      systemd.enable = cfg.systemd.enable;
    };
  };
}
