{
  description = "Quickshell bar config with a dev shell and a reusable Home Manager module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      quickshell,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});

      configDir = ./config;

      quickshellPackage = system: quickshell.packages.${system}.default;

      runtimePackages = pkgs: with pkgs; [
        bash
        coreutils
        curl
        pamixer
        pavucontrol
        rofi
        wireplumber
      ];

      fontPackages = pkgs: with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.iosevka
        noto-fonts-color-emoji
      ];

      fontConfig = pkgs: pkgs.makeFontsConf {
        fontDirectories = fontPackages pkgs;
      };

      quickshellConfigWrapper =
        pkgs: system:
        let
          quickshellPkg = quickshellPackage system;
          fontConfigFile = fontConfig pkgs;
        in
        pkgs.writeShellApplication {
          name = "quickshell-config";
          runtimeInputs = [ quickshellPkg ] ++ runtimePackages pkgs ++ fontPackages pkgs;
          text = ''
            export FONTCONFIG_FILE=${fontConfigFile}
            exec quickshell --path ${configDir} "$@"
          '';
        };
    in
    {
      packages = forAllSystems (
        system: pkgs:
        let
          quickshell-config = quickshellConfigWrapper pkgs system;
        in
        {
          inherit quickshell-config;
          default = quickshell-config;
        }
      );

      apps = forAllSystems (
        system: _: {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/quickshell-config";
            meta = {
              description = "Run quickshell with this repository's configuration";
            };
          };
        }
      );

      devShells = forAllSystems (
        system: pkgs:
        let
          quickshellPkg = quickshellPackage system;
          qtDeclarative = pkgs.kdePackages.qtdeclarative;
          quickshellQmlPath = "${quickshellPkg}/lib/qt-6/qml";
          qtQmlPath = "${qtDeclarative}/lib/qt-6/qml";
          fontConfigFile = fontConfig pkgs;
        in
        {
          default = pkgs.mkShell {
            packages = [
              quickshellPkg
              qtDeclarative
              pkgs.just
            ] ++ runtimePackages pkgs ++ fontPackages pkgs;

            env = {
              QML_IMPORT_PATH = "${quickshellQmlPath}:${qtQmlPath}";
              QML2_IMPORT_PATH = "${quickshellQmlPath}:${qtQmlPath}";
              QUICKSHELL_QML_PATH = quickshellQmlPath;
              QT_QML_PATH = qtQmlPath;
              FONTCONFIG_FILE = fontConfigFile;
            };
          };
        }
      );

      formatter = forAllSystems (
        system: pkgs:
        pkgs.writeShellApplication {
          name = "nixfmt";
          runtimeInputs = [ pkgs.nixfmt ];
          text = ''
            args=()
            for arg in "$@"; do
              case "$arg" in
                -* | *.nix) args+=("$arg") ;;
              esac
            done
            if [ ''${#args[@]} -eq 0 ]; then
              exit 0
            fi
            exec nixfmt "''${args[@]}"
          '';
        }
      );

      homeModules.default = import ./nix/home-module.nix {
        inherit configDir;
        quickshellPackages = quickshell.packages;
      };
      homeModules.quickshell-config = self.homeModules.default;

      homeManagerModules = self.homeModules;
    };
}
