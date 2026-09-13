# AGENTS.md

Quickshell bar config packaged as a flake: QML in `config/`, Home Manager module in `nix/`, dev shell + `justfile` for development.

## Commands

- Run all dev commands inside `nix develop`: `just run`, `just lint`, `just fmt`, `just check`, `just update`.
- `just run` = `quickshell --path ./config`, which hot-reloads on save. `nix run .` runs a store copy of the config — no hot reload, not for development.
- `nix fmt` only formats `.nix` files; the flake's formatter is a wrapper that drops non-Nix paths because nixfmt would choke on `justfile`, `config/shell.qml`, and `flake.lock`.
- Flakes only see git-tracked files: `git add` new files or `nix build .` / `nix flake check` won't see them.

## Gotchas

- Quickshell comes from the upstream input `github:quickshell-mirror/quickshell` (currently 0.3.1), not nixpkgs. Keep `quickshell.inputs.nixpkgs.follows = "nixpkgs"` — mismatched Qt deps crash quickshell.
- `qmllint` ignores `QML_IMPORT_PATH`; pass `-I "$QUICKSHELL_QML_PATH" -I "$QT_QML_PATH"` explicitly (set by the dev shell, used in `just lint`).
- `qmllint` reports `Type PanelWindow is not creatable [uncreatable-type]`. Known quickshell false positive, exits 0; do not work around it.
- `nix flake check` omits aarch64 without a remote builder; `just check` uses `--no-build` for the eval-only pass.

## Architecture

- `config/shell.qml` is the entrypoint; both the flake wrapper and the HM module point at `configDir = ./config` defined in `flake.nix`. One bar per monitor is `ShellRoot` + `Variants { model: Quickshell.screens }`, with `required property var modelData` on each `PanelWindow`.
- `nix/home-module.nix` is a factory (`{ configDir, quickshellPackages } -> { config, lib, pkgs, ... }:`). It wraps HM's `programs.quickshell`, so the consumer's Home Manager must include that module (present in current unstable/26.05). Options live under `programs.quickshell-config`; the default package resolves from the quickshell input for `pkgs.stdenv.hostPlatform.system`.
- Flake outputs: `homeModules.default` (also `homeManagerModules` legacy alias), `packages.default` (the `quickshell-config` wrapper), `apps.default`, `devShells.default`.

## Verifying changes

- The bar can be live-tested on the running Hyprland session: `just run`, then `hyprctl layers | grep quickshell` should show one layer surface per monitor. Kill the exact quickshell PID when done.
- The user also runs waybar on the same monitors; a second bar stacking below it is expected, not a bug.
- Verify module changes without touching the real config: create a throwaway flake in `/tmp` that sets `inputs.nixpkgs.follows = "nixpkgs"` on both the Home Manager input and this repo (via a `path:` URL), then build `homeConfigurations.<name>.activationPackage`.
