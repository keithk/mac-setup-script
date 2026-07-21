#!/usr/bin/env bash
#
# Mac setup: Homebrew + Brewfile, oh-my-zsh + spaceship prompt, mise, git config.
# Safe to re-run — every step is idempotent.
#
# Usage:
#   ./setup.sh              # core setup (work machines)
#   ./setup.sh --personal   # core + personal apps (Discord, Steam, ...)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PERSONAL=false
[[ "${1:-}" == "--personal" ]] && PERSONAL=true

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

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

step "Packages and apps (brew bundle)"
brew bundle --file="$REPO_DIR/Brewfile"
if $PERSONAL; then
  step "Personal packages and apps"
  brew bundle --file="$REPO_DIR/Brewfile.personal"
fi

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

step "Runtimes (mise)"
mise use --global node@lts bun@latest

step "Default browser"
if ! defaultbrowser | grep -q '^\* *zen'; then
  # macOS pops a confirmation dialog — click "Use Zen"
  defaultbrowser zen
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

step "Done"
echo "Open a new terminal (or run: exec zsh) to pick everything up."
echo "Machine-specific PATH entries and secrets go in ~/.zshrc.local."
