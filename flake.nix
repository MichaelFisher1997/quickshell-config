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

      quickshellConfigWrapper =
        pkgs: system:
        pkgs.writeShellApplication {
          name = "quickshell-config";
          runtimeInputs = [ (quickshellPackage system) ];
          text = ''
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
        in
        {
          default = pkgs.mkShell {
            packages = [
              quickshellPkg
              qtDeclarative
              pkgs.just
            ];

            env = {
              QML_IMPORT_PATH = "${quickshellQmlPath}:${qtQmlPath}";
              QML2_IMPORT_PATH = "${quickshellQmlPath}:${qtQmlPath}";
              QUICKSHELL_QML_PATH = quickshellQmlPath;
              QT_QML_PATH = qtQmlPath;
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
