# The terminfo module helps with portability between different hosts and
# terminals by mapping capability names to their values.
#
# See man:terminfo(5) for more information.
zmodload zsh/terminfo

if [[ "$OSTYPE" == darwin* ]]; then
  # NOTE(ivy): This fixes backspace for some terminal applications. It's
  # dependent on my terminal configuration which uses '\033[3~'.
  stty erase '^?'
fi

# Switch to application mode when zle is active, since only then are values from
# $terminfo valid.
#
# See http://zsh.sourceforge.net/FAQ/zshfaq04.html#l25
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init { echoti smkx }
  function zle-line-finish { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# Home and End keys jump between beginning and end of command line
bindkey '^A' vi-beginning-of-line
bindkey '^E' vi-end-of-line

# tmux sends different key codes for Home and End
bindkey "\e[1~" vi-beginning-of-line
bindkey "\e[4~" vi-end-of-line

# Option-Left and Option-Right jumps between words
bindkey '^[b' vi-backward-word
bindkey '^[f' vi-forward-word

# Shift-Tab reverse navigates completions
if [[ -n "${terminfo[cbt]}" ]]; then
  bindkey "${terminfo[cbt]}" reverse-menu-complete
fi

# Enable history searching and cycling on the command line, similar to
# Fish shell's history search feature.
zplug "zsh-users/zsh-history-substring-search"

# Up and Down arrow keys search command line history
if [[ -n "${terminfo[kcuu1]}" ]]; then
  bindkey "${terminfo[kcuu1]}" history-substring-search-up
fi
if [[ -n "${terminfo[kcud1]}" ]]; then
  bindkey "${terminfo[kcud1]}" history-substring-search-down
fi

# 'k' and 'j' keys search command line history in vi mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
