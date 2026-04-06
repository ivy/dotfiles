# Containerfile -- Dotfiles Development Environment
#
# Builds a container image with all dotfiles tooling pre-installed.
# Each dependency gets its own layer so rebuilds only reinstall what changed.
#
# Build:
#   podman build --secret id=github_token,env=GITHUB_TOKEN -t dotfiles .
#
# Quick build with GitHub token (avoids rate limits):
#   GITHUB_TOKEN=$(gh auth token) podman build --secret id=github_token,env=GITHUB_TOKEN -t dotfiles .
#
# Run:
#   podman run -it dotfiles
#
# Override identity:
#   podman build \
#     --build-arg GIT_USER_NAME="Your Name" \
#     --build-arg GIT_USER_EMAIL="you@example.com" \
#     --secret id=github_token,env=GITHUB_TOKEN \
#     -t dotfiles .

FROM registry.fedoraproject.org/fedora:latest

# =============================================================================
# Layer: system packages
# =============================================================================
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y \
        --setopt=install_weak_deps=False \
        --setopt=keepcache=True \
        bc \
        ca-certificates \
        curl \
        gcc \
        gcc-c++ \
        git \
        git-lfs \
        htop \
        jq \
        make \
        ncurses \
        openssl-devel \
        pkg-config \
        tar \
        tmux \
        unzip \
        util-linux-user \
        zsh

# =============================================================================
# Layer: cosign (signature verification)
# =============================================================================
ARG COSIGN_VERSION=v2.5.3
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -fsSL "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${ARCH}" \
        -o /usr/local/bin/cosign \
    && chmod +x /usr/local/bin/cosign

# =============================================================================
# Layer: mise (tool version manager)
# =============================================================================
RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh

# =============================================================================
# Layer: chezmoi (dotfiles manager)
# =============================================================================
RUN --mount=type=secret,id=github_token \
    ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && AUTH_HEADER="" \
    && [ -f /run/secrets/github_token ] && AUTH_HEADER="Authorization: token $(cat /run/secrets/github_token)" \
    && VERSION=$(curl -fsSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} https://api.github.com/repos/twpayne/chezmoi/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//') \
    && curl -fsSL "https://github.com/twpayne/chezmoi/releases/download/v${VERSION}/chezmoi_${VERSION}_linux_${ARCH}.tar.gz" \
        | tar -xzf - -C /usr/local/bin chezmoi \
    && chmod +x /usr/local/bin/chezmoi

# =============================================================================
# Non-root user
# =============================================================================
ARG USERNAME=ivy
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g "${USER_GID}" "${USERNAME}" \
    && useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /usr/bin/zsh "${USERNAME}"

ENV CONTAINER=podman \
    HOME=/home/ivy \
    XDG_CACHE_HOME=/home/ivy/.cache \
    XDG_CONFIG_HOME=/home/ivy/.config \
    XDG_DATA_HOME=/home/ivy/.local/share \
    XDG_STATE_HOME=/home/ivy/.local/state \
    PATH="/home/ivy/.local/bin:${PATH}"

# =============================================================================
# Dotfiles source
# =============================================================================
COPY --chown=ivy:ivy . /home/ivy/.dotfiles

USER ivy
WORKDIR /home/ivy

# =============================================================================
# Layer: chezmoi apply + mise tools
#
# chezmoi apply places the mise config, then its run_onchange script runs
# `mise install`. The secret mount provides GITHUB_TOKEN to avoid rate limits.
# Cache mounts at staging paths speed up rebuilds — mise downloads and installs
# into the cache, then we copy the results into the image layer.
# =============================================================================
ARG GIT_USER_NAME="Ivy Evans"
ARG GIT_USER_EMAIL="ivy@ivyevans.net"
ARG USE_BEDROCK=false

RUN --mount=type=cache,target=/tmp/mise-data,uid=1000,gid=1000 \
    --mount=type=cache,target=/tmp/mise-cache,uid=1000,gid=1000 \
    --mount=type=cache,target=/tmp/mise-state,uid=1000,gid=1000 \
    --mount=type=secret,id=github_token,mode=0444 \
    export GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    && export MISE_DATA_DIR=/tmp/mise-data \
    && export MISE_CACHE_DIR=/tmp/mise-cache \
    && export MISE_STATE_DIR=/tmp/mise-state \
    && chezmoi init --apply \
        --source="/home/ivy/.dotfiles" \
        --working-tree="/home/ivy/.dotfiles" \
        --promptString "Git user.name=${GIT_USER_NAME}" \
        --promptString "Git user.email=${GIT_USER_EMAIL}" \
        --promptBool "Use AWS Bedrock for Claude Code=${USE_BEDROCK}" \
        --promptString "1Password ref for OpenAI Codex=" \
        --promptString "1Password ref for Claude API=" \
        --promptString "1Password ref for Buildkite=" \
    && mkdir -p /home/ivy/.local/share/mise \
    && cp -a /tmp/mise-data/. /home/ivy/.local/share/mise/

CMD ["zsh", "-l"]
