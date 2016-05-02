# ~/.zlogin is sourced after ~/.zshrc and should contain commands that should
# only be executed in login shells.
#
# See http://zsh.sourceforge.net/Intro/intro_3.html

# zsh configs are spread out across partials under zsh/zlogin.d/
for loginfile in "$ZDOTDIR/.zsh/zlogin.d/"*.zsh; do
  source "$loginfile"
done

# Use .zlogin.local for host-specific tweaks that you don't want in your public,
# versioned repository.
if [[ -r "$ZDOTDIR/.zlogin.local" ]]; then
  source "$ZDOTDIR/.zlogin.local"
fi