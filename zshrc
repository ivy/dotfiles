# ~/.zshrc is sourced for interactive and login shells. It should contain
# commands that customize the behavior of zsh. Environment variables and tweaks
# that should effect *all* invocations of the shell should instead be
# placed in ~/.zshenv.
#
# See http://zsh.sourceforge.net/Intro/intro_3.html

# Reload zsh startup files by re-executing the shell.
reload!() {
  exec zsh "$@"
}

for rcfile in "$XDG_CONFIG_HOME/zsh/rc.d/"*.zsh; do
  source "$rcfile"
done

# Use .zshrc.local for host-specific tweaks that you don't want in your public,
# versioned repository.
if [ -r "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# Finally, initialize zsh's completion system.
autoload -U compinit
compinit
