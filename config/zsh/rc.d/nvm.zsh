# nvm.zsh -- Initialize Node Version Manager (NVM)
#
# See https://github.com/nvm-sh/nvm#readme

function {
  local search_dirs=(
    "$HOME/.nvm" /usr/local/opt/nvm
  )

  for dir in "${search_dirs[@]}"; do
    [[ -r "$dir/nvm.sh" ]] || continue

    export NVM_DIR="$HOME/.nvm"

    source "$dir/nvm.sh"
    source "$dir/etc/bash_completion.d/nvm"
    break
  done
}
