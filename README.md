# quickshell-config

A minimal [Quickshell](https://quickshell.org) configuration: one 32px bar at the top of every monitor with a clock. Packaged as a Nix flake for local development and as a reusable Home Manager module.

## Layout

```
config/shell.qml      # the shell entry point (bar + clock)
nix/home-module.nix   # Home Manager module
flake.nix             # devShell, packages, apps, homeModules
justfile              # dev commands
```

## Development

```sh
nix develop
just run     # quickshell --path ./config, hot-reloads on save
just lint    # qmllint with quickshell + Qt import paths
just fmt     # qmlformat --inplace
just check   # nix flake check + just lint
just update  # nix flake update
```

`nix develop` provides quickshell 0.3.x (upstream flake), the QML tools, `just`, the CLI tools used by the bar, and the Iosevka/emoji fonts. `nix run .` runs the config from a store copy (no hot reload).

The dictation module calls `nix-tts`, which is a user-specific package and is not available in nixpkgs. Keep it in the user's profile, or add it through `programs.quickshell-config.extraPackages` when using the Home Manager module.

The shell disables Qt's unused XDG desktop portal registration because this layer-shell bar does not use portal APIs.

## Home Manager

Add this repo as an input and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    quickshell-config = {
      url = "path:/path/to/quickshell-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, quickshell-config, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      # ...
      modules = [
        quickshell-config.homeModules.default
        {
          programs.quickshell-config.enable = true;
        }
      ];
    };
  };
}
```

Requires a Home Manager with `programs.quickshell` (26.05 or unstable). The module installs quickshell, deploys this config to `~/.config/quickshell/<configName>/shell.qml`, and starts it via a systemd user service.

### Options

| Option | Default | Description |
| --- | --- | --- |
| `programs.quickshell-config.enable` | `false` | Install and run this configuration |
| `programs.quickshell-config.package` | upstream quickshell for the system | Package to use; `null` to manage it yourself |
| `programs.quickshell-config.configName` | `"quickshell-config"` | Name of the installed configuration |
| `programs.quickshell-config.systemd.enable` | `true` | Autostart with the graphical session |
| `programs.quickshell-config.extraPackages` | `[]` | Additional commands used by the configuration, such as a custom `nix-tts` package |

To disable autostart:

```nix
programs.quickshell-config.systemd.enable = false;
```

Then launch manually with:

```sh
quickshell --config quickshell-config
```

## Notes

- Quickshell 0.3.x is tracked from `github:quickshell-mirror/quickshell`; because `inputs.nixpkgs.follows = "nixpkgs"` is set both here and in the example consumer config, it builds against your Nixpkgs (avoiding mismatched Qt dependencies).
- The bar uses wlr-layer-shell, so it works on Hyprland, Sway, etc. Remove any other bar (e.g. waybar) to avoid stacking.
