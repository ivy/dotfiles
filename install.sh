#!/bin/sh
#
# install.sh -- Chezmoi Dotfiles Installer
# 
# This script installs Chezmoi (https://chezmoi.io) and initializes your
# dotfiles from this repository. It's designed for modern POSIX-y systems:
#   - Alpine Linux
#   - Debian/Ubuntu
#   - Fedora/RHEL
#   - macOS
#
# HOW TO USE:
#   1. Clone this repository: git clone https://github.com/ivy/dotfiles.git
#   2. Run the installer: ./install.sh
#   3. The script will:
#      - Install Chezmoi to ~/.local/bin
#      - Initialize your dotfiles from this repo
#      - Apply all configurations automatically
#
# EXAMPLE USAGE:
#   $ git clone https://github.com/ivy/dotfiles.git
#   $ cd dotfiles
#   $ ./install.sh
#   Installing Chezmoi to /home/user/.local/bin...
#   Chezmoi installed successfully
#   Initializing dotfiles from /home/user/dotfiles...
#   [Chezmoi output showing applied configurations]

set -o errexit
set -o nounset

# Default values
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
CHEZMOI_URL="get.chezmoi.io"

# Get the directory where this script is located
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Ensure BIN_DIR exists
mkdir -p "$BIN_DIR"

# Function to detect available download tool
get_download_cmd() {
    if command -v curl >/dev/null 2>&1; then
        echo "curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        echo "wget -qO-"
    else
        echo "Error: Neither curl nor wget is available" >&2
        exit 1
    fi
}

# Function to download and install Chezmoi
install_chezmoi() {
    download_cmd=$(get_download_cmd)
    
    echo "Installing Chezmoi to $BIN_DIR..."
    
    # Download and install Chezmoi with better error handling
    if ! $download_cmd "$CHEZMOI_URL" | sh -s -- -b "$BIN_DIR"; then
        echo "Error: Failed to download or install Chezmoi" >&2
        exit 1
    fi
    
    # Verify installation
    if [ ! -x "$BIN_DIR/chezmoi" ]; then
        echo "Error: Chezmoi installation failed - binary not found" >&2
        exit 1
    fi
    
    echo "Chezmoi installed successfully to $BIN_DIR"
}

# Add BIN_DIR to PATH if not already there
add_to_path() {
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) export PATH="$BIN_DIR:$PATH" ;;
    esac
}

# Main execution
main() {
    echo "Installing Chezmoi dotfiles manager..."
    
    # Install Chezmoi
    install_chezmoi
    
    # Add BIN_DIR to PATH
    add_to_path
    
    # Set chezmoi variable for the exec command
    chezmoi="$BIN_DIR/chezmoi"
    
    echo "Initializing dotfiles from $script_dir..."
    
    # Execute the initialization command
    exec "$chezmoi" init --apply --source="$script_dir"
}

main "$@"
