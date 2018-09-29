#eval (python -m virtualfish)
status --is-interactive; and . (pyenv init -|psub)
status --is-interactive; and . (pyenv virtualenv-init -|psub)
set -gx PYENV_ROOT /usr/local/opt/pyenv
set fish_path $HOME/.oh-my-fish
set fish_plugins brew rbenv pyenv
set GPG_TTY (tty)
set CPPFLAGS -I/usr/local/opt/openssl/include
set LDFLAGS -L/usr/local/opt/openssl/lib


# fish settings
set -g theme_color_scheme base16-light
set -g theme_display_vi no
set -x VIRTUAL_ENV_DISABLE_PROMPT 1

source ~/.fish_aliases
source ~/.fish_variables