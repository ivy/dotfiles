function {
  local possible_brews=(/opt/homebrew/bin/brew /usr/local/bin/brew)
  local brew

  for brew in ${possible_brews[@]}; do
    if [ -x "$brew" ]; then
      eval "$("$brew" shellenv)"
      fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
      break
    fi
  done
}
