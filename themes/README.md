# Themes

Each ops mode has an Omarchy theme. `install.sh` symlinks every folder here into `~/.config/omarchy/themes/`, and `omarsenal-mode` applies them with `omarchy-theme-set`.

| Theme | Mode | Background | Accent | Highlight |
| --- | --- | --- | --- | --- |
| ops-red | Red | `#0a0606` | `#c1121f` | `#ff4d4d` |
| ops-blue | Blue | `#060a12` | `#1e90ff` | `#5fb4ff` |
| ops-purple | Purple | `#0a0612` | `#8a2be2` | `#b57bff` |

## Status

Each theme ships its wallpaper in `backgrounds/`. The color files (Hyprland borders, Waybar, terminal, launcher, lock screen) are still to be written. Generate them against the current Omarchy theme format by copying a built-in theme from `~/.local/share/omarchy/themes/` and swapping in the palette above. `AGENTS.md` has the steps.

The wallpapers are 1024x572 concepts. Replace them with 3840x2160 renders before a tagged release.
