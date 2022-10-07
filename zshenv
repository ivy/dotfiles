# ~/.zshenv is the first startup file that zsh will read commands from. It is
# sourced on all invocations of the shell. As such, it should not contain
# commands that produce output or assume the shell is attached to a TTY.
#
# See http://zsh.sourceforge.net/Intro/intro_3.html

# XDG_CONFIG_HOME specifies the directory where config files are read from.
# See https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

for envfile in "$XDG_CONFIG_HOME/zsh/env.d/"*.zsh; do
  source "$envfile"
done

# Use .zshenv.local for secrets and host-specific tweaks that you don't want in
# your public, versioned repository.
if [ -r "$HOME/.zshenv.local" ]; then
  source "$HOME/.zshenv.local"
fi
