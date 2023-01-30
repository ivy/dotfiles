# Reset OSX $PATH with system-wide defaults.
#if [[ "$OSTYPE" == darwin* ]]; then
#  export PATH=""
#  eval `/usr/libexec/path_helper -s`
#fi

# Add ~/bin to executables path.
export PATH="$HOME/bin:$PATH"

# Add *whitelisted* bin/ directories to executable path.
# See https://twitter.com/tpope/status/165631968996900865
export PATH=".git/safe/../../bin:.git/safe/../../node_modules/.bin:$PATH"
