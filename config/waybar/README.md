# Waybar module

Omarsenal does not edit Omarchy's Waybar config for you, since Omarchy updates may change it. Add the module by hand.

1. In `~/.config/waybar/config.jsonc`, add `"custom/omarsenal"` to `modules-center` (or wherever you want it), then add:

```jsonc
"custom/omarsenal": {
  "exec": "~/.local/bin/omarsenal-waybar",
  "return-type": "json",
  "interval": 15,
  "signal": 8
}
```

2. In `~/.config/waybar/style.css`, add:

```css
#custom-omarsenal.red    { color: #ff4d4d; }
#custom-omarsenal.blue   { color: #5fb4ff; }
#custom-omarsenal.purple { color: #b57bff; }
```

3. Restart Waybar with `omarchy-restart-waybar` or log out and back in.

The module is blank in off mode. `omarsenal-mode` and `omarsenal-target use` send signal 8 so it updates instantly.
