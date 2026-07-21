#!/usr/bin/env bash
#
# Mac setup: Homebrew + modular Brewfiles, oh-my-zsh + spaceship prompt, mise, git config.
# Safe to re-run — every step is idempotent.
#
# Core (shell, git, CLI essentials) installs on every machine. Everything else
# is an opt-in module. Bare `./setup.sh` prompts for each module interactively;
# pass module flags to skip the prompts for scripted / unattended re-runs.
#
# Usage:
#   ./setup.sh                     # interactive — prompts for each module
#   ./setup.sh --core              # core only, no prompts
#   ./setup.sh --dev --browsers    # core + named modules, no prompts
#   ./setup.sh --all               # core + every module, no prompts
#
# Modules: --dev --web-local --browsers --containers --apps --personal

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  sed -n '3,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Module toggles. Interactive by default; any selection flag switches to
# non-interactive and installs exactly what was named (plus core).
DEV=false
WEB_LOCAL=false
BROWSERS=false
CONTAINERS=false
APPS=false
PERSONAL=false
INTERACTIVE=true

for arg in "$@"; do
  case "$arg" in
    --all|-y|--yes)
      DEV=true; WEB_LOCAL=true; BROWSERS=true; CONTAINERS=true; APPS=true; PERSONAL=true
      INTERACTIVE=false ;;
    --core)       INTERACTIVE=false ;;
    --dev)        DEV=true;        INTERACTIVE=false ;;
    --web-local)  WEB_LOCAL=true;  INTERACTIVE=false ;;
    --browsers)   BROWSERS=true;   INTERACTIVE=false ;;
    --containers) CONTAINERS=true; INTERACTIVE=false ;;
    --apps)       APPS=true;       INTERACTIVE=false ;;
    --personal)   PERSONAL=true;   INTERACTIVE=false ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown option: $arg"; echo; usage; exit 1 ;;
  esac
done

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

# confirm "question" default(true=yes|false=no) — empty answer takes the default
confirm() {
  local q="$1" def="$2" reply hint
  $def && hint="[Y/n]" || hint="[y/N]"
  read -rp "$q $hint " reply || true
  case "$reply" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *) $def ;;
  esac
}

if $INTERACTIVE; then
  step "Choose modules"
  if confirm "Dev tools (node/bun/python, editors, media)?"       true;  then DEV=true;        fi
  if confirm "Subeta/Laravel local stack (Herd, DB, caddy)?"      false; then WEB_LOCAL=true;  fi
  if confirm "Browsers (Firefox, Chrome, Zen)?"                   false; then BROWSERS=true;   fi
  if confirm "Docker Desktop?"                                    false; then CONTAINERS=true; fi
  if confirm "GUI apps (Notion, Slack, Figma, Obsidian, ...)?"     true;  then APPS=true;       fi
  if confirm "Personal apps (Discord, Steam, ...)?"               false; then PERSONAL=true;   fi
fi

step "Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "Re-run this script once the Command Line Tools install finishes."
  exit 0
fi

step "Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# brew bundle installs in parallel by default (HOMEBREW_BUNDLE_JOBS=auto). That
# races when a cask and its add-ons install at once — the VS Code cask gets
# unpacked by two workers concurrently and corrupts itself. Serialize for safety.
export HOMEBREW_BUNDLE_JOBS=1

# A pre-installed app brew didn't install (e.g. an IT- or App Store-managed one)
# makes that one entry fail — but shouldn't abort the whole setup. Collect the
# failures, keep going, and report them at the end.
BUNDLE_FAILURES=()
run_bundle() {  # label file
  step "$1"
  if ! brew bundle --file="$REPO_DIR/$2"; then
    BUNDLE_FAILURES+=("$2")
    printf '\033[1;33m!! %s had failures — continuing (see summary at the end).\033[0m\n' "$2"
  fi
}

run_bundle "Core packages and apps" "Brewfile"

if $DEV;        then run_bundle "Dev tools"                  "Brewfile.dev";        fi
if $WEB_LOCAL;  then run_bundle "Subeta/Laravel local stack" "Brewfile.web-local";  fi
if $BROWSERS;   then run_bundle "Browsers"                   "Brewfile.browsers";   fi
if $CONTAINERS; then run_bundle "Containers"                 "Brewfile.containers"; fi
if $APPS;       then run_bundle "GUI apps"                   "Brewfile.apps";       fi
if $PERSONAL;   then run_bundle "Personal apps"             "Brewfile.personal";   fi

step "oh-my-zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

step "Spaceship prompt"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [[ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]]; then
  git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
fi
ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

step "Shell config"
for file in zshrc zprofile; do
  target="$HOME/.$file"
  if [[ -f "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.backup"
    echo "Backed up existing $target to $target.backup"
  fi
  ln -sf "$REPO_DIR/configs/$file" "$target"
done
# Machine-specific config and secrets go here, never in the repo
touch "$HOME/.zshrc.local"

if $DEV; then
  step "Runtimes (mise)"
  mise use --global node@lts bun@latest python@latest
fi

if $BROWSERS; then
  step "Default browser"
  if command -v defaultbrowser &>/dev/null && ! defaultbrowser | grep -q '^\* *zen'; then
    # macOS pops a confirmation dialog — click "Use Zen"
    defaultbrowser zen
  fi
fi

step "Git config"
git config --global user.name "Keith Kurson"
if [[ -z "$(git config --global user.email || true)" ]]; then
  read -rp "Git email for this machine [keith@keithkurson.net]: " git_email
  git config --global user.email "${git_email:-keith@keithkurson.net}"
fi
git_configs=(
  "init.defaultBranch main"
  "pull.rebase true"
  "rebase.autostash true"
  "push.default simple"
  "push.autoSetupRemote true"
  "rerere.enabled true"
  "credential.helper osxkeychain"
  "color.ui auto"
)
for config in "${git_configs[@]}"; do
  git config --global ${config}
done

step "SSH key"
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_ed25519"
fi

step "GitHub auth"
if ! gh auth status &>/dev/null; then
  # Offers to upload the SSH key to GitHub during login
  gh auth login --git-protocol ssh
fi

step "Claude Code"
if ! command -v claude &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

step "macOS defaults"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # list view
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.dock tilesize -int 53
killall Finder Dock 2>/dev/null || true

step "iTerm2 settings"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$REPO_DIR/configs/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

if [[ ${#BUNDLE_FAILURES[@]} -gt 0 ]]; then
  step "Heads up: some brew bundles had failures"
  printf ' - %s\n' "${BUNDLE_FAILURES[@]}"
  echo "Usually a pre-installed app brew won't overwrite. Inspect with:"
  echo "  brew bundle check --file=<file>"
  echo "To let brew adopt an identical pre-existing app: brew install --cask --adopt <name>"
fi

step "Done"
echo "Open a new terminal (or run: exec zsh) to pick everything up."
echo "Machine-specific PATH entries and secrets go in ~/.zshrc.local."
