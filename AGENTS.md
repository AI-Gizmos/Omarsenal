# AGENTS.md

You are working in Omarsenal, an overlay that turns a stock Omarchy install into a security workstation. Omarchy is Arch Linux with Hyprland. Omarsenal never forks or edits Omarchy's own files; it layers on top through symlinks and sourced config.

This file is the source of truth for every AI coding agent (Claude Code, Codex and others). `CLAUDE.md` only points here.

## Repo layout

- `install.sh`, `uninstall.sh`: entry points. Every install path has a matching uninstall path.
- `modules/`: install logic. `lib.sh` holds shared helpers; `install-category.sh` reads one package list.
- `packages/*.txt`: one package per line, grouped by category. Add tools here, never hardcode installs in scripts.
- `scripts/`: user-facing commands, linked into `~/.local/bin` as `omarsenal-*`.
  - `ops-mode.sh` → `omarsenal-mode red|blue|purple|off|status`
  - `target.sh` → `omarsenal-target new|use|current|list|check`
  - `scope-check.py` → `omarsenal-scope check|args`
  - `ops-workspace.sh` → `omarsenal-workspace`
- `config/`: Hyprland binds, shell integration, Waybar module, tmux, and `omarsenal.conf.example`.
- `themes/ops-red`, `themes/ops-blue`, `themes/ops-purple`: Omarchy themes for each mode. Palettes are in `themes/README.md`.
- `labs/`: Docker practice targets, bound to localhost.
- `docs/`: `tools.md` (every tool and its purpose), `safety.md`, `roadmap.md`.

Runtime state lives in `~/.local/state/omarsenal/` (`mode`, `target`, install ledgers). User settings live in `~/.config/omarsenal/omarsenal.conf`.

## Creating or finishing a theme

1. Copy an existing Omarsenal theme folder, for example `themes/ops-red/`, to `themes/<new-name>/`. Use lowercase-hyphenated names.
2. Match the current Omarchy theme format by looking at a built-in theme in `~/.local/share/omarchy/themes/`. Do not guess file names; copy the structure you find there.
3. Apply one palette across every file: Hyprland borders, Waybar, terminal, launcher, lock screen. Record the palette in `themes/README.md`.
4. Place wallpapers in `themes/<new-name>/backgrounds/`. Ask the user for images or describe options. Do not download images from unknown sources.
5. Check contrast on terminal text and the bar.
6. Tell the user to test with `omarchy-theme-set <new-name>`, then report what changed.

## Adding a tool

1. Prefer the official Arch repos, then BlackArch, then the AUR.
2. Add the package name to the right `packages/*.txt` file with a short comment if the name is not obvious.
3. Add a row to `docs/tools.md`.
4. Never add tools from unvetted GitHub repos or curl-pipe-bash installers.

## Target profiles

- Create profiles only with `omarsenal-target new <name>`. Profiles live in `$OMARSENAL_TARGETS` (default `~/omarsenal-targets`), never inside this repo.
- Refuse to run any recon until `omarsenal-target check` passes: `authorization.md` says `Status: APPROVED` and `scope.txt` has entries. Ask the user to confirm both.
- Run `omarsenal-scope check <target>` before every tool run against a host. Stop and ask on anything out of scope.
- Save raw tool output under the matching folder (`recon/whois`, `recon/dns`, `recon/osint`, `scans/nmap`, `web`). Never delete raw output.
- Parse results into `recon/hosts.csv` and `scans/services.csv`, deduplicating by IP and hostname. Keep the header rows.
- One file per finding in `findings/`, named `NNN-short-title.md`, with severity, affected hosts, evidence and remediation.
- Keep `profile.md` current: summary, key hosts, open services, findings so far, next steps.

## Coding rules

- Bash scripts start with `set -euo pipefail` and must be safe to rerun.
- Support `DRY_RUN=1` through the `run` helper in `modules/lib.sh` for anything that changes the system.
- Lines appended to user files end with `# omarsenal` so `uninstall.sh` can remove them.
- Do not modify files under `~/.local/share/omarchy`.
- Test with `bash -n` and `shellcheck` before committing.

## Guardrails

- Never run `install.sh`, `uninstall.sh`, `pacman`, `yay`, `sudo` or `systemctl` without asking the user first.
- Never run offensive tools against any target unless the user confirms they own it or hold written authorization, and it passes the scope check.
- Never commit secrets, API keys, engagement data, client names or target folders.
