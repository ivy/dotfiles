export CHRUBY_ROOT="$HOMEBREW_PREFIX"

if [ -d "$CHRUBY_ROOT" ]; then
  source "$CHRUBY_ROOT/share/chruby/chruby.sh"
  source "$CHRUBY_ROOT/share/chruby/auto.sh"
fi
