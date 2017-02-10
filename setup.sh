#!/usr/bin/env bash

brews=(
  archey
  aws-shell
  cheat
  clib
  coreutils
  dfc
  findutils
  fontconfig --universal
  fpp
  fzf
  git
  git-extras
  git-lfs
  gnuplot --with-qt
  go
  gpg
  hh
  htop
  httpie
  iftop
  imagemagick
  lighttpd
  lnav
  lumen
  mackup
  macvim
  mas
  micro
  mtr
  ncdu
  nmap
  node --with-full-icu
  poppler
  postgresql
  pgcli
  python
  python3
  scala
  sbt
  thefuck
  tmux
  tree
  trash
  wget
)

casks=(
  adobe-reader
  airdroid
  atom
  betterzipql
  cakebrew
  cleanmymac
  commander-one
  datagrip
  docker
  dropbox
  firefox
  geekbench
  google-chrome
  google-drive
  github-desktop
  hosts
  handbrake
  intellij-idea
  istat-menus
  istat-server  
  launchrocket
  licecap
  lumen
  iterm2
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  macdown
  private-eye
  satellite-eyes
  slack
  spotify
  steam
  tunnelbear
  vlc
  volumemixer
  webstorm
  xquartz
)

pips=(
  pip
  glances
  ohmu
  pythonpy
)

gems=(
  bundle
)

npms=(
  fenix-cli
  gitjk
  kill-tabs
  n
  nuclide-installer
)

clibs=(
  bpkg/bpkg
)

bkpgs=(
)

gpg_key='12F902C5C6906E5E'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "core.pager cat"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "core.whitespace trailing-space,space-before-tab"
  "apply.whitespace fix"
  "rerere.enabled true"
  "user.name keithkurson"
  "user.email keith@keithkurson.net"
  "user.signingkey ${gpg_key}"
)

apms=(
  atom-beautify
  circle-ci
  ensime
  intellij-idea-keymap
  language-scala
  minimap
)

fonts=(
  font-source-code-pro
)

omfs=(
  jacaetevha
  osx
  thefuck
)

######################################## End of app list ########################################
set +e
set -x

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
fi
brew doctor
brew tap homebrew/dupes

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

echo "Installing ruby ..."
brew install ruby-install chruby
ruby-install ruby
# TODO: enable auto switch here by following instructions
echo "ruby-2.3.1" > ~/.ruby-version
ruby -v

echo "Installing Java ..."
brew cask install java

echo "Installing packages ..."
brew info ${brews[@]}
install 'brew install' ${brews[@]}

echo "Tapping casks ..."
brew tap caskroom/fonts
brew tap caskroom/versions

echo "Installing software ..."
brew cask info ${casks[@]}
install 'brew cask install' ${casks[@]}

echo "Installing secondary packages ..."
# TODO: add info part of install or do reinstall?
install 'pip install --upgrade' ${pips[@]}
install 'gem install' ${gems[@]}
install 'clib install' ${clibs[@]}
install 'bpkg install' ${bpkgs[@]}
install 'npm install --global' ${npms[@]}
install 'apm install' ${apms[@]}
install 'brew cask install' ${fonts[@]}

echo "Upgrading bash ..."
brew install bash
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
mv ~/.bash_profile ~/.bash_profile_backup
mv ~/.bashrc ~/.bashrc_backup
mv ~/.gitconfig ~/.gitconfig_backup
cd; curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
source ~/.bash_profile

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done
gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}

echo "Installing mac CLI ..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/guarinogabriel/mac-cli/master/mac-cli/tools/install)"

echo "Updating ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system
mac update

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Run `mackup restore` after DropBox has done syncing"

#echo "Setting up fish shell ..."
#brew install fish chruby-fish
#echo $(which fish) | sudo tee -a /etc/shells
#mkdir -p ~/.config/fish/
#echo "source /usr/local/share/chruby/chruby.fish" >> ~/.config/fish/config.fish
#echo "source /usr/local/share/chruby/auto.fish" >> ~/.config/fish/config.fish
#echo "export GOPATH=/usr/libs/go" >> ~/.config/fish/config.fish
#echo "export PATH=$PATH:$GOPATH/bin" >> ~/.config/fish/config.fish
#chsh -s $(which fish)
#curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
#for omf in ${omfs[@]}
#do
#  fish -c "omf install ${omf}"
#done

echo "Done!"
