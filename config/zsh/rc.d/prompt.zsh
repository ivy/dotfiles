autoload -U colors && colors

# Enable command line syntax highlighting
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# Automatically suggest commands based on history and completions.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=14"
zplug "zsh-users/zsh-autosuggestions"

# Use pure prompt theme
zplug "sindresorhus/pure"

# Enable vim-like modal editing.
# TODO(ivy): Set up https://github.com/jeffreytse/zsh-vi-mode
bindkey -v

function {
  local funcdir="$ZPLUG_HOME/functions"

  if [ -r "$funcdir/prompt_pure_setup" ] && [ -r "$funcdir/async" ]; then
    return
  fi

  mkdir -p "$funcdir"
  ln -fs ../repos/sindresorhus/pure/async.zsh "$funcdir/async"
  ln -fs ../repos/sindresorhus/pure/pure.zsh "$funcdir/prompt_pure_setup"
}
