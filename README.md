# mac-setup-script

Sets up a new Mac the way I like it: Homebrew + a Brewfile, zsh with oh-my-zsh
and the [Spaceship prompt](https://spaceship-prompt.sh/), [mise](https://mise.jdx.dev/)
for language runtimes, and my git defaults.

```shell
git clone https://github.com/keithk/mac-setup-script.git
cd mac-setup-script
./setup.sh              # work machine (core tools + apps)
./setup.sh --personal   # also install personal apps (Discord, Steam, ...)
```

Safe to re-run; every step is idempotent.

## What's in here

- `Brewfile` — core CLI tools, apps, fonts, and VS Code extensions
- `Brewfile.personal` — extras for personal machines only
- `configs/zshrc`, `configs/zprofile` — symlinked to `~/.zshrc` / `~/.zprofile`
- `setup.sh` — orchestrates everything

Machine-specific PATH entries and secrets go in `~/.zshrc.local`, which the
zshrc sources but git never sees.

To capture what's installed on the current machine back into the Brewfile:
`brew bundle dump --file=Brewfile.dump` and diff against `Brewfile`.
