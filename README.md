# Cat-Tarot

## Overview

A single-player 3D tarot roguelike built with Godot 4.6. Rules, controls and balance are in
[`docs/GAMEPLAY.md`](docs/GAMEPLAY.md).

## Requirements

- Godot **4.6** (`godot` on `PATH`)
- Python **3.8+** (asset tooling)
- `gh` CLI (only to publish assets / fetch private releases)

## Getting the assets

Raw assets (`assets/`) and the archives built from them are **not** in Git. They are published as
two equivalent archives on this repository's GitHub Release tagged `assets`
(<https://github.com/GekoLynx-Studio/Cat-Tarot/releases/tag/assets>):

- `assets.zip` — Windows: `Expand-Archive assets.zip -DestinationPath .` (or Extract All)
- `assets.tar.gz` — macOS/Linux: `tar -xzf assets.tar.gz`

Script (all OSes):

```bash
tools/fetch-assets.sh                       # macOS / Linux / Git Bash
powershell -File tools\fetch-assets.ps1     # Windows PowerShell
```

It uses a local bundle if present, otherwise downloads from the release, extracts to `assets/`, and
verifies against the committed `assets.sha256`.

## Run

```bash
godot --path .
```

Debug seed: `godot --path . -- --seed=1234`.

## Tests

```bash
godot --headless --path . --import
godot --headless --path . res://tests/rules_test.tscn
godot --headless --path . res://tests/ui_smoke.tscn
godot --headless --path . res://tests/interactions_test.tscn
```

## Project layout

```text
Cat-Tarot/
|-- project.godot
|-- README.md            uniform structure
|-- AGENTS.md            agent/contributor conventions (identical across games)
|-- docs/GAMEPLAY.md     rules, controls, balance
|-- assets/              raw assets (git-ignored; restored from the release)
|-- scenes/              main, card_3d, deck_3d, dice_3d, restart_button_3d
|-- scripts/             rules engine, UI, audio, card/dice/deck nodes
|-- tests/               rules, UI smoke, interactions
|-- tools/               asset tooling (assets.py + *.sh / *.ps1)
|-- .githooks/           pre-commit / commit-msg / pre-push
`-- .github/             CI workflow + PR template
```

## Development

- Commit messages follow **Conventional Commits**.
- Hooks are enabled via `core.hooksPath=.githooks`; `pre-commit` blocks a stale asset stamp and
  checks `gdformat` when installed.
- **If you change anything under `assets/`:**

```bash
tools/pack-assets.sh
tools/push-assets.sh
git add assets.sha256
git commit -m "chore(assets): update bundle"
```

Never commit `assets/`, `assets.tar.gz` or `assets.zip`. No Git LFS.

## Cross-platform

| Task | Linux / macOS | Windows |
|------|---------------|---------|
| Fetch assets | `tools/fetch-assets.sh` | `tools\fetch-assets.ps1` |
| Pack assets | `tools/pack-assets.sh` | `tools\pack-assets.ps1` |
| Publish assets | `tools/push-assets.sh` | `tools\push-assets.ps1` |
| Git hooks | native `sh` | Git for Windows (bundled `sh`) |

## Contributing

- Read `AGENTS.md` first; it is identical in every game repo of this workspace.
- Keep the PR title in Conventional Commits form and follow `.github/pull_request_template.md`.
- AI-assisted forks/PRs are welcome under the same conventions.

## Credits & licenses

Card art, icons, the Chinese UI font (`乐米栀夏浅风体`), the 3D die and the tabletop audio are
third-party or supplied sources; see `assets/LICENSES.md` (travels in the bundle). The ambient
background track is original to this project.

## Status

Complete prototype.
