#!/bin/bash
# Install Claude Code via official installer
# https://docs.anthropic.com/en/docs/claude-code/overview
#
# This runs once per machine. Claude Code auto-updates after installation.

[ -n "${DEBUG:-}" ] && set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

# Skip if claude is already installed
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code already installed: $(claude --version 2>/dev/null || echo 'version unknown')"
    exit 0
fi

echo "Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

echo "Claude Code installation complete"
