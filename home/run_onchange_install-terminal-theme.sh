#!/bin/bash

install_tokyo_night_theme() {
    local theme_url="https://github.com/tboltondev/tokyo-night.terminal/raw/20a27c60bfa61ac0b6098a22bddcdde565b899c8/tokyo-night.terminal"
    local expected_sha256="6c8f0bde0192954430d416b2d11ccdaf33efdaa81b65a471877bb1df1e7b505c"
    local theme_file="/tmp/tokyo-night.terminal"
    local theme_name="tokyo-night"

    echo "Downloading Tokyo Night Terminal theme..."

    # Download the theme
    if ! curl -fsSL "$theme_url" -o "$theme_file"; then
        echo "Error: Failed to download theme from $theme_url"
        return 1
    fi

    echo "Validating SHA256 checksum..."

    # Calculate and verify SHA256
    local actual_sha256
    if command -v shasum >/dev/null 2>&1; then
        actual_sha256=$(shasum -a 256 "$theme_file" | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        actual_sha256=$(sha256sum "$theme_file" | cut -d' ' -f1)
    else
        echo "Error: Neither shasum nor sha256sum found"
        rm -f "$theme_file"
        return 1
    fi

    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        echo "Error: SHA256 mismatch!"
        echo "Expected: $expected_sha256"
        echo "Actual:   $actual_sha256"
        rm -f "$theme_file"
        return 1
    fi

    echo "✓ SHA256 verified successfully"
    echo "Installing Tokyo Night theme..."

    # Install the theme
    open "$theme_file"
    sleep 2

    # Set as default (optional)
    echo "Setting Tokyo Night as default theme..."
    defaults write com.apple.terminal "Default Window Settings" "$theme_name"
    defaults write com.apple.terminal "Startup Window Settings" "$theme_name"

    # Cleanup
    rm -f "$theme_file"

    echo "✓ Tokyo Night theme installed successfully!"
    echo "You may need to restart Terminal to see all changes."
}

# Only run on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    install_tokyo_night_theme
else
    echo "This script is only for macOS"
    exit 1
fi
