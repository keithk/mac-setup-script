# mac-setup-script

Sets up a new Mac the way I like it: Homebrew + modular Brewfiles, zsh with
oh-my-zsh and the [Spaceship prompt](https://spaceship-prompt.sh/),
[mise](https://mise.jdx.dev/) for language runtimes, and my git defaults.

```shell
git clone https://github.com/keithk/mac-setup-script.git
cd mac-setup-script
./setup.sh              # interactive — prompts for each optional module
```

Bare `./setup.sh` installs **core** (shell, git, CLI essentials) on every
machine, then prompts for each optional module. Pass module flags to skip the
prompts on scripted or unattended re-runs:

```shell
./setup.sh --dev --browsers   # core + named modules, no prompts
./setup.sh --core             # core only, no prompts
./setup.sh --all              # core + every module, no prompts
```

Safe to re-run; every step is idempotent.

## Modules

| Module | Flag | What's in it |
|---|---|---|
| core | *(always)* | git, gh, mise, fzf, tmux, 1Password, Raycast, iTerm2, the shell setup |
| dev | `--dev` | node/bun/**python** runtimes, pnpm, VS Code + Zed + extensions, media tools (ffmpeg, imagemagick) |
| web-local | `--web-local` | Laravel Herd stack + Subeta data tooling (dnsmasq, mkcert, caddy, MySQL, valkey, TablePlus) |
| browsers | `--browsers` | Firefox, Chrome, Zen — and sets Zen as default. Skip where IT manages browsers |
| containers | `--containers` | Docker Desktop + its VS Code extension |
| apps | `--apps` | GUI productivity apps: Notion, Obsidian, Slack, Zoom, Figma, Tower, Tailscale |
| personal | `--personal` | Discord, Steam, Beeper, deploy CLIs, ... |

Typical machines:

- **Work box:** `--dev --apps` (browsers come from IT)
- **Subeta box:** `--dev --web-local --containers --browsers --apps --personal`

## What's in here

- `Brewfile` — core CLI tools, apps, and fonts (installs everywhere)
- `Brewfile.<module>` — one file per optional module above
- `configs/zshrc`, `configs/zprofile` — symlinked to `~/.zshrc` / `~/.zprofile`
- `configs/iterm2/` — iTerm2 preferences; setup points iTerm at this folder
- `setup.sh` — orchestrates everything, including: SSH key generation +
  `gh auth login`, the Claude Code CLI, macOS defaults (Finder path bar,
  list view, no network .DS_Store), and mise runtimes (with `--dev`)

Machine-specific PATH entries and secrets go in `~/.zshrc.local`, which the
zshrc sources but git never sees.

To capture what's installed on the current machine back into a Brewfile:
`brew bundle dump --file=Brewfile.dump` and diff against the relevant files.
