# quickshell-config

A self-contained [Quickshell](https://quickshell.org) screen-edge shell whose visual language is adapted from the reference Eww bar: near-black `#0f0f17` surfaces, cool gray (`#bfc9db`) and lilac (`#d7beda`) text, rainbow workspace rings, and peach (`#e4c9af`) weather SVGs. A continuous frame surrounds every monitor, with controls integrated into its top edge. Packaged as a Nix flake for local development and as a reusable Home Manager module.

## Design

The shell is flush with all four screen edges: a 40px top panel joins 10px side and bottom borders around a transparent desktop opening with 24px rounded inner corners. There is no floating outer pill or gap around the shell. The top panel holds three control zones:

- **Left**: Launcher, Workspaces, Backlight, Battery, then adjacent media controls and track label.
- **Center** (screen-centered): Weather, Clock, Volume.
- **Right**: Dictation, CPU, Memory, Disk, Tray.

Modules sit directly on the near-black frame surface like the Eww bar: no pill fill, just text with the Eww per-module colors — CPU lilac `#d7beda`, memory peach `#e0b089`, disk and battery sage `#afbea2`, volume green `#98c379` (red `#e06c75` when muted), clock time cool gray with a lilac date, and weather/brightness in peach. Workspaces render as Font Awesome circles — hollow when occupied, filled when focused — each in its workspace color (1 red `#e06c75`, 2 orange `#d19a66`, 3 yellow `#e5c07b`, 4 green `#98c379`, 5/9 cyan `#56b6c2`, 6 blue `#61afef`, 7 violet `#c678dd`, 8 pink `#ff79c6`, 10 gray `#abb2bf`). The launcher is the Eww apps glyph in red-pink `#e5809e` on a sunken `#22242b` chip, and the media controls/label form slender outlined pills with a hairline `rgba(255,255,255,0.06)` ring. Hover feedback is the Eww white 6% wash, with press feedback and short color transitions on state changes; green/yellow/red stay reserved for real states (battery, dictation, muted volume).

The desktop opening and decorative borders pass pointer input through. Four transparent reservation surfaces keep tiled/maximized windows inside the frame; the full-screen drawing surface itself reserves no space. Frame dimensions live in `config/Bar.qml`. The integrated perimeter is combined with a top-attached dashboard drawer (below); Caelestia's wallpaper picker and other drawers are not implemented.

## Drawer

`components/Drawer.qml` is a reusable panel attached seamlessly to the bottom edge of the top bar strip: square top corners in the exact frame color (no seam), large rounded bottom corners, and no outer outline. It is not a floating popover — it shares the bar's layer surface and reads as part of the frame. Opening and closing animate the panel height (cubic easing, ~300 ms) while the content is clipped, like a drawer unrolling from the frame; switching tabs keeps the drawer open, swaps the page instantly, and re-sizes the panel to the tab's content height with a short animation.

- **Tabs**: Dashboard, Weather, Sound, Performance. The drawer surface is the flat Eww popup color `#0f0f17` with no outer outline. Dashboard is a card mosaic after Caelestia's dashboard, built from plain QML with Eww card styling (transparent surface, hairline `rgba(255,255,255,0.08)` ring): small current-weather card (peach monochrome SVG, cool-gray temperature, blue-gray description; click switches to the Weather tab, which owns retries), user card (`~/.face` avatar with a glyph fallback, username, OS from `/etc/os-release`, desktop from the environment, uptime from `/proc/uptime`), stacked `HH ••• mm` clock with the weekday (minutes precision, from the Clock module), the compact Monday-first month calendar (`CalendarTab { compact: true }` — navigation, today reset, day selection), vertical CPU/memory/storage rings colored per metric (lilac/peach/sage with shared warn thresholds), and an MPRIS media card with album artwork, previous/play-pause/next, and an empty state. Weather and Performance are described below.
- **Width**: centered and clamped to the monitor width minus the side frame. Tabs default to `preferredWidth: 720`; the Dashboard tab widens the drawer to 920 (animated). Below ~848 px of drawer width the media card reflows into a full-width row under the mosaic, and no calendar cell grows to fill empty space.
- **Sound**: default output name, volume slider (0–100%, applied on release), mute, and Settings (`pavucontrol`). Known Bluetooth devices (paired, trusted, or connected) appear in a bounded scrollable list with native connect/disconnect controls and pending states. Connected devices show their reported battery, including 0%, or "Battery unavailable". Adapter state and unavailable/empty cases are shown; the drawer never powers on, scans, or pairs automatically.
- **Data**: tabs reuse the existing bar modules (Clock, Weather, Volume, CPU, Memory, Disk), with no duplicate pollers. Bluetooth uses native `Quickshell.Bluetooth` / BlueZ. The Weather module additionally exposes the raw wttr.in JSON; the disk gauge computes used % from used/total (the pill shows available %). The dashboard adds only two cheap reads: `/etc/os-release` once, and `/proc/uptime` every 60 s while the dashboard is the visible tab and the drawer is open; media comes from the MPRIS service via the same `ActivePlayer` selector the bar modules use.
- **Input**: the window mask is a union of regions — the top bar strip plus the visible part of the animated drawer (rounded bottom corners stay click-through). The mask updates live during the animation, and the desktop outside the drawer remains click-through. The gauge labels are honest: no GPU gauge exists because no GPU telemetry is wired up.
- **Keyboard**: while the drawer is open, a Hyprland focus grab keeps input on the shell and enables Escape (close) and Left/Right (cycle tabs). Closing releases the grab and disables keyboard focus.
- **Closing**: click outside the shell's input region, use the close button, click the same trigger again, or press Escape. The drawer also closes after the pointer spends three continuous seconds outside both the drawer and the central weather/clock/volume controls; returning cancels the timer. Outside-click dismissal uses Hyprland's focus-grab protocol rather than a full-screen mouse overlay. Clicking another bar control remains available without dismissing it immediately.

| Module | Shows | Interactions |
| --- | --- | --- |
| Launcher | apps glyph, red-pink on sunken chip | Left: `rofi -show drun`; Right: `~/.config/rofi/run.sh` |
| Workspaces | hollow rings (filled when focused), one color each | Click to activate; wheel to cycle; urgent/focused highlight |
| Backlight | brightness % | Wheel writes to sysfs; tooltip |
| Battery | charge % / time | Any click alternates views; state colors; tooltip |
| Player controls + label | prev/toggle/next, artist – title | Left: previous; Middle: toggle; Right: next; tooltip (sticky player) |
| Weather | peach monochrome SVG + temp for Ashton-Under-Lyne | Left: toggle Weather drawer; no hover popup |
| Clock | `HH:mm \| dd/MM/yy` | Left: toggle Dashboard drawer; no hover popup |
| Volume | sink volume % / muted state | Left: toggle Sound drawer; Middle: mute; Right: pavucontrol; wheel: ±5%; no hover popup |
| Dictation | `nix-tts` state | Any click toggles; state colors |
| CPU | usage % / GHz | Any click: alternate usage / frequency; does not open the drawer |
| Memory | used % / used-total GiB | Any click: alternate views; does not open the drawer |
| Disk | available space % / used-total | Any click: alternate views; does not open the drawer |
| Tray | status notifier icons | Left: activate; Right: menu; passive items hidden; tooltips |

Clicking a trigger for the tab that is already open toggles the drawer closed; clicking a different trigger while open switches tabs without closing.
The clock opens the Dashboard (first tab); the weather card inside it switches to the full Weather tab. Open the drawer through the clock, weather, or volume, then select Performance to view the gauges.

The **Weather** tab keeps all of its data (current conditions, feels-like/wind/humidity, hourly strip for today) and uses Eww-inspired ringed daily cards distributed across the content width. The usual three-day wttr.in forecast uses blue for today (tinted `rgba(97,175,239,0.15)` with a solid `#61afef` ring), then green and yellow at 35% ring alpha. Orange and red remain available if additional days are returned; no days are fabricated. Cards show peach SVGs, colored highs, muted lows (`#6b7280`), cyan (`#56b6c2`) rainfall in mm, and per-day sunrise/sunset/moon lines below. The **calendar** uses the Eww scheme: weekday columns Mon–Sun in blue/green/yellow/orange/red/violet/pink (`#61afef`, `#98c379`, `#e5c07b`, `#d19a66`, `#e06c75`, `#c678dd`, `#ff79c6`), every day inside a thin circular outline tinted with its weekday color, today filled solid with dark `#0f0f17` text, adjacent-month dates muted `#3e424f`, and small violet month pills plus a blue-gray Today pill for navigation. The **Performance** gauges use the Eww track color `#38384d` with per-metric arcs (CPU lilac, memory peach `#e0b089`, disk sage) that shift to yellow above 70 and red above 90.

## Layout

```
config/shell.qml               # entry point: one bar per screen
config/Bar.qml                 # screen frame, edge reservations, top controls, drawer wiring + input mask
config/components/Pill.qml     # shared pill + theme palette
config/components/Drawer.qml   # reusable top-attached animated drawer (tabs, close, keys)
config/components/Gauge.qml    # circular percentage gauge
config/components/Tooltip.qml  # anchored tooltip popup
config/components/ActivePlayer.qml
config/drawer/DashboardTab.qml   # drawer page: dashboard card mosaic (tabId: dashboard)
config/drawer/CalendarTab.qml    # month grid logic; compact variant embedded in the dashboard
config/drawer/WeatherTab.qml     # drawer page: current/daily/hourly forecast (tabId: weather)
config/drawer/PerformanceTab.qml # drawer page: CPU/memory/disk gauges (tabId: performance)
config/drawer/SoundTab.qml       # drawer page: output volume + known Bluetooth devices (tabId: sound)
config/modules/*.qml           # one file per bar module
config/assets/weather/*.svg    # six peach condition icons from the Eww reference
nix/home-module.nix            # Home Manager module
flake.nix                       # devShell, packages, apps, homeModules
justfile                        # dev commands
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

`nix develop` provides quickshell 0.3.x (upstream flake), the QML tools, `just`, the CLI tools used by the bar, and the fonts (`JetBrainsMono Nerd Font`, the reference Eww bar's primary family, used for text, controls, weather-detail and moon-phase glyphs; plus `Iosevka Nerd Font` as a retained fallback and Noto Color Emoji as an unused-at-runtime fallback). Weather conditions use bundled SVGs rather than font glyphs. `nix run .` runs the config from a store copy (no hot reload).

The dictation module calls `nix-tts`, which is a user-specific package and is not available in nixpkgs. Keep it in the user's profile, or add it through `programs.quickshell-config.extraPackages` when using the Home Manager module.

The shell disables Qt's unused XDG desktop portal registration because this layer-shell bar does not use portal APIs.

Bluetooth requires a running system BlueZ service and an available adapter (on NixOS, enable `hardware.bluetooth.enable`). Power and pairing remain managed by your system or existing Bluetooth manager. Battery reporting depends on device/BlueZ support; unavailable telemetry is not estimated. No additional Bluetooth CLI dependency is needed. Audio continues to use the packaged `pamixer`, `wpctl`, and `pavucontrol`; muted volume is polled independently of mute state.

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
- The shell uses wlr-layer-shell; its workspace module requires Hyprland. Other bars are not stopped or replaced. Their reservations add to this shell's reservations, and an edge-attached bar may overlap its top controls. Use one primary shell/bar for the intended integrated layout.
- Flakes only see files known to Git. Add new QML files to Git before building or distributing; `just run` and `just lint` read the working tree directly.
- Weather conditions use the six original peach (`#e4c9af`) SVGs from the reference Eww `images/` directory, mapped centrally from wttr.in condition codes (not Eww's WMO codes). The supplied `sun.svg` and `cloud-sun.svg` have identical artwork. Moon phases and weather-detail indicators remain Nerd Font glyphs with native rendering. Theme colors follow the reference Eww `eww.scss`; keep `Pill.qml`'s shared palette and the per-file copies in sync when changing colors.
