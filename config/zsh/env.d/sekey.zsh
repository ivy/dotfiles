# sekey.zsh enables use of Touch ID for SSH authentication.
#
# See https://github.com/sekey/sekey

if [[ $OSTYPE == darwin* ]] && [[ -S "$HOME/.sekey/ssh-agent.ssh" ]]; then
  export SSH_AUTH_SOCK="$HOME/.sekey/ssh-agent.ssh"
fi
