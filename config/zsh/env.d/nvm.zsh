# nvm.zsh -- Initialize Node Version Manager (NVM)
#
# See https://github.com/nvm-sh/nvm#readme

# NVM_VERSION_DEFAULT caches the default Node version number. This saves
# valuable seconds when changing directories, ensuring we keep the command
# prompt as responsive as possible.
NVM_VERSION_DEFAULT=""

# load-nvmrc switches the NVM Node version based on the current working
# directory. Based on https://stackoverflow.com/a/39519460
load-nvmrc() {
  local current_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [[ -z "$nvmrc_path" ]]; then
    if [[ -z "$NVM_VERSION_DEFAULT" ]]; then
      NVM_VERSION_DEFAULT="$(nvm version default)"
    fi

    if [[ "$current_version" != "$NVM_VERSION_DEFAULT" ]]; then
      echo 'Switching to default NVM version.'
      nvm use default
    fi
    return
  fi

  local nvmrc_version="$(nvm version "$(<"$nvmrc_path")")"

  if [[ "$nvmrc_version" = "N/A" ]]; then
    nvm install
  elif [[ "$nvmrc_version" != "$current_version" ]]; then
    nvm use
  fi
}

function {
  local search_dirs=(
    /opt/homebrew/opt/nvm
    /usr/local/opt/nvm
    "$HOME/.nvm"
  )

  for dir in "${search_dirs[@]}"; do
    [[ -r "$dir/nvm.sh" ]] || continue

    export NVM_DIR="$HOME/.nvm"

    source "$dir/nvm.sh"
    # TODO: Source zsh-users/zsh-completions instead
    #source "$dir/etc/bash_completion.d/nvm"

    autoload -U add-zsh-hook
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc

    break
  done
}
