# gnu-utils.zsh updates the search path to replace various BSD utilities with
# their GNU counterparts. I personally find these variants to be more
# user-friendly and featurefully than what ships with macOS.
#
# Note: There's a chance you might run into unexpected behavior when running
# certain scripts. I haven't personally run into this yet but it's something to
# keep in mind!

function {
  if [[ "$OSTYPE" != darwin* ]]; then
    return
  fi

  local search_paths=(
    coreutils
    findutils
    gnu-sed
    gnu-tar
    gnu-which
    grep
  )

  for p in $search_paths; do
    local dir="/usr/local/opt/$p/libexec/gnubin"
    if [[ -d "$dir" ]]; then
      PATH="/usr/local/opt/$p/libexec/gnubin:$PATH"
    fi
  done
}
