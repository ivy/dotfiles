# gnu-utils.zsh updates the search path to replace various BSD utilities with
# their GNU counterparts. I personally find these variants to be more
# user-friendly and featureful than what ships with macOS.
#
# Note: As a Mac user I sometimes run into small compatibility issues with
# coworkers who are using the default BSD utils. I haven't run into the inverse
# yet but it's something to be aware of.

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
