#!/usr/bin/env bash
#
# install.sh — Dotfiles installer with concurrent progress display
#
# Installs developer tools (Homebrew, cosign, mise, chezmoi, Claude Code),
# then applies dotfiles via chezmoi. Steps run concurrently where possible
# with an animated progress UI (TTY) or plain-text output (non-TTY/CI).
#
# Usage: ./install.sh [OPTIONS] [-- CHEZMOI_ARGS...]
#        ./install.sh -h  for full help
#
[[ "$DEBUG" ]] && set -x
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────

CHEZMOI_REPO="twpayne/chezmoi"
COSIGN_REPO="sigstore/cosign"
GITHUB_API_URL="https://api.github.com"
GITHUB_RELEASES_URL="https://github.com"
LOG_BASE="${TMPDIR:-/tmp}/dotfiles-install"
DEFAULT_BIN_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Flag defaults ────────────────────────────────────────────────────

FLAG_FORCE=false
FLAG_NUKE=false
FLAG_EXPLICIT_FORCE=false
FLAG_DEBUG=false
FLAG_DRY_RUN=false
FLAG_QUIET=false
BIN_DIR="$DEFAULT_BIN_DIR"
FLAG_NO_VERIFY=false
FLAG_NO_PKG_MGR=false
CHEZMOI_VERSION=""
COSIGN_VERSION=""
GIT_USER_NAME=""
GIT_USER_EMAIL=""
FLAG_BEDROCK=""
CHEZMOI_PASSTHROUGH=()
LOG_DIR="${LOG_DIR:-}"
_ORIGINAL_CMD="${_ORIGINAL_CMD:-}"

# ── Usage ────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: install.sh [OPTIONS] [-- CHEZMOI_ARGS...]

Dotfiles installer with concurrent progress display.

Options:
  -h, --help                Show this help message
  -f, --force               Reinstall all tools and re-run setup scripts
  --nuke                    Scorched earth: uninstall, wipe state, reinstall
  -n, --dry-run             Show what would happen without making changes
  -d, --debug               Enable shell trace output
  -q, --quiet               Suppress all non-error output (logs still written)

  --bin-dir DIR             Binary install directory (default: ~/.local/bin)
  --no-verify               Skip cosign signature verification for chezmoi
  --no-package-manager      Skip brew/apt/dnf, download binaries directly

  --chezmoi-version VER     Pin chezmoi version (default: latest)
  --cosign-version VER      Pin cosign version (default: from cli-versions.toml)

  --git-name NAME           Set git user.name without prompting
  --git-email EMAIL         Set git user.email without prompting
  --bedrock                 Enable AWS Bedrock for Claude Code
  --no-bedrock              Disable AWS Bedrock for Claude Code

  Unknown flags and args after -- are passed through to chezmoi init.

Examples:
  ./install.sh                                    Install normally
  ./install.sh -n                                 Preview what would happen
  ./install.sh -f                                 Force reinstall everything
  ./install.sh --nuke                             Start completely from scratch
  ./install.sh --nuke -f                          Non-interactive nuke (CI)
  ./install.sh --git-name "J" --git-email "j@e"   Skip identity prompts
  ./install.sh -q --no-bedrock                    Quiet CI install
  ./install.sh -- --one-shot                      Pass --one-shot to chezmoi
EOF
  exit 0
}

# ── Flag parser ──────────────────────────────────────────────────────

parse_flags() {
  while (($# > 0)); do
    case $1 in
    -h | --help) usage ;;
    -f | --force)
      FLAG_FORCE=true
      FLAG_EXPLICIT_FORCE=true
      shift
      ;;
    --nuke)
      FLAG_NUKE=true
      FLAG_FORCE=true
      shift
      ;;
    -d | --debug)
      FLAG_DEBUG=true
      shift
      ;;
    -n | --dry-run)
      FLAG_DRY_RUN=true
      shift
      ;;
    -q | --quiet)
      FLAG_QUIET=true
      shift
      ;;
    --bin-dir)
      (($# >= 2)) || {
        printf 'error: --bin-dir requires an argument\n' >&2
        exit 1
      }
      BIN_DIR=$2
      shift 2
      ;;
    --no-verify)
      FLAG_NO_VERIFY=true
      shift
      ;;
    --no-package-manager)
      FLAG_NO_PKG_MGR=true
      shift
      ;;
    --chezmoi-version)
      (($# >= 2)) || {
        printf 'error: --chezmoi-version requires an argument\n' >&2
        exit 1
      }
      CHEZMOI_VERSION=$2
      shift 2
      ;;
    --cosign-version)
      (($# >= 2)) || {
        printf 'error: --cosign-version requires an argument\n' >&2
        exit 1
      }
      COSIGN_VERSION=$2
      shift 2
      ;;
    --git-name)
      (($# >= 2)) || {
        printf 'error: --git-name requires an argument\n' >&2
        exit 1
      }
      GIT_USER_NAME=$2
      shift 2
      ;;
    --git-email)
      (($# >= 2)) || {
        printf 'error: --git-email requires an argument\n' >&2
        exit 1
      }
      GIT_USER_EMAIL=$2
      shift 2
      ;;
    --bedrock)
      FLAG_BEDROCK=true
      shift
      ;;
    --no-bedrock)
      FLAG_BEDROCK=false
      shift
      ;;
    --)
      shift
      CHEZMOI_PASSTHROUGH+=("$@")
      break
      ;;
    *)
      CHEZMOI_PASSTHROUGH+=("$1")
      shift
      ;;
    esac
  done
}

# ── Version resolution ───────────────────────────────────────────────

resolve_versions() {
  if [[ -z $CHEZMOI_VERSION ]]; then
    CHEZMOI_VERSION="latest"
  fi
  if [[ -z $COSIGN_VERSION ]]; then
    local versions_file="$SCRIPT_DIR/home/dot_config/dotfiles/cli-versions.toml"
    if [[ -f $versions_file ]]; then
      COSIGN_VERSION=$(grep '^cosign' "$versions_file" | cut -d'"' -f2 || true)
    fi
    if [[ -z $COSIGN_VERSION ]]; then COSIGN_VERSION="latest"; fi
  fi
}

# ── Logging infrastructure ───────────────────────────────────────────

init_logging() {
  local timestamp
  timestamp=$(date +%Y-%m-%dT%H-%M-%S)
  LOG_DIR="${LOG_BASE}/${timestamp}"
  mkdir -p "$LOG_DIR"
  # Atomically update latest symlink
  ln -sfn "$LOG_DIR" "${LOG_BASE}/latest"
}

write_summary() {
  [[ -z ${LOG_DIR:-} ]] && return
  local summary="$LOG_DIR/summary.txt"
  {
    printf 'timestamp: %s\n' "$(date -Iseconds 2>/dev/null || date)"
    printf 'command: %s\n' "$_ORIGINAL_CMD"
    local i
    for i in "${!STEP_IDS[@]}"; do
      printf 'step: %s state=%s elapsed=%ds message=%s\n' \
        "${STEP_IDS[$i]}" "${STEP_STATES[$i]}" "${STEP_ELAPSED[$i]}" "${STEP_MESSAGES[$i]}"
    done
    local has_failure=false
    for s in "${STEP_STATES[@]}"; do
      [[ $s == "failed" ]] && {
        has_failure=true
        break
      }
    done
    printf 'result: %s\n' "$([[ $has_failure == true ]] && echo "failed" || echo "ok")"
  } >"$summary"
}

# ── TTY detection ────────────────────────────────────────────────────
# Detect once before script(1) re-exec; preserve across re-exec via export.

if [[ -z ${IS_TTY+x} ]]; then
  IS_TTY=false
  [[ -t 1 ]] && [[ -t 0 ]] && IS_TTY=true
  export IS_TTY
fi

# ── Colors ───────────────────────────────────────────────────────────
# Initialized empty; populated by _setup_colors after flag parsing.

RST="" BOLD="" DIM=""
CYAN="" GREEN="" RED="" YELLOW="" WHITE="" GRAY=""
CLR=""

_setup_colors() {
  if [[ $IS_TTY == true ]]; then
    RST=$'\033[0m' BOLD=$'\033[1m' DIM=$'\033[2m'
    CYAN=$'\033[36m' GREEN=$'\033[32m' RED=$'\033[31m'
    YELLOW=$'\033[33m' WHITE=$'\033[97m' GRAY=$'\033[90m'
    CLR=$'\033[K'
  fi
}

# ── Braille spinner frames ──────────────────────────────────────────

readonly FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
readonly FRAME_INTERVAL=0.08

# ── Terminal width ──────────────────────────────────────────────────

TERM_WIDTH=80

_detect_width() {
  if [[ $IS_TTY == true ]]; then
    local w
    w=$(stty size 2>/dev/null </dev/tty) && w=${w##* } && ((w > 0)) 2>/dev/null && {
      TERM_WIDTH=$w
      return
    }
    w=$(tput cols 2>/dev/null) && ((w > 0)) 2>/dev/null && {
      TERM_WIDTH=$w
      return
    }
  fi
  TERM_WIDTH=80
}

_repeat() {
  local char=$1 count=$2 result=""
  local i
  for ((i = 0; i < count; i++)); do result+="$char"; done
  printf '%s' "$result"
}

# ── Utility functions ────────────────────────────────────────────────

detect_system() {
  local os arch
  case "$(uname -s)" in
  Linux*) os="linux" ;;
  Darwin*) os="darwin" ;;
  *)
    printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
  esac
  case "$(uname -m)" in
  x86_64 | amd64) arch="amd64" ;;
  aarch64 | arm64) arch="arm64" ;;
  armv7l | armv8l) arch="arm" ;;
  i386 | i686) arch="i386" ;;
  *)
    printf 'Unsupported arch: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
  esac
  echo "${os}_${arch}"
}

get_download_cmd() {
  if command -v curl >/dev/null 2>&1; then
    echo "curl -fsSL"
  elif command -v wget >/dev/null 2>&1; then
    echo "wget -qO-"
  else
    printf 'Neither curl nor wget available\n' >&2
    exit 1
  fi
}

verify_checksum() {
  local checksums=$2
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$checksums" --ignore-missing
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$checksums" --ignore-missing
  else
    printf 'No checksum tool available\n' >&2
    exit 1
  fi
}

need_sudo() {
  if [ -w /var/lib/apt/lists ] 2>/dev/null ||
    [ -w /var/lib/dnf ] 2>/dev/null ||
    [ -w /var/lib/pacman ] 2>/dev/null ||
    [ -w /var/cache/apk ] 2>/dev/null; then
    return 1
  else
    return 0
  fi
}

run_with_sudo() {
  if need_sudo; then
    if ! command -v sudo >/dev/null 2>&1; then
      printf 'sudo required but not available\n' >&2
      return 1
    fi
    sudo "$@"
  else
    "$@"
  fi
}

add_to_path() {
  case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) export PATH="$BIN_DIR:$PATH" ;;
  esac
}

_find_brew() {
  command -v brew 2>/dev/null && return 0
  local p
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $p ]] && {
      echo "$p"
      return 0
    }
  done
  return 1
}

tool_healthy() {
  local cmd=$1
  command -v "$cmd" >/dev/null 2>&1 || return 1
  case $cmd in
  cosign) cosign version >/dev/null 2>&1 ;;
  *) "$cmd" --version >/dev/null 2>&1 ;;
  esac
}

tool_version() {
  case $1 in
  cosign) cosign version 2>/dev/null | grep -o 'v[0-9][0-9.]*' | head -1 ;;
  mise) mise --version 2>/dev/null | awk '{print $1}' ;;
  chezmoi) chezmoi --version 2>/dev/null | grep -o 'v[0-9][0-9.]*' | head -1 ;;
  brew) brew --version 2>/dev/null | head -1 | sed 's/Homebrew //' ;;
  claude) claude --version 2>/dev/null | head -1 ;;
  *) "$1" --version 2>/dev/null | head -1 ;;
  esac
}

prefill_name() {
  case "$(uname -s)" in
  Darwin) id -F 2>/dev/null ;;
  Linux) getent passwd "$(whoami)" 2>/dev/null | cut -d: -f5 | cut -d, -f1 ;;
  esac
}

prefill_email() {
  case "$(uname -s)" in
  Darwin) defaults read MobileMeAccounts Accounts 2>/dev/null | grep AccountID | cut -d'"' -f2 ;;
  *) return 1 ;;
  esac
}

# ── Step registry ────────────────────────────────────────────────────

STEP_LABELS=()
STEP_CMDS=()
STEP_STATES=()
STEP_START_SEC=()
STEP_ELAPSED=()
STEP_MESSAGES=()
STEP_IDS=()
STEP_DEPS=()
STEP_PIDS=()
STEP_MSG_FILES=()
_PLAIN_EMITTED=()

_step_id_to_index() {
  local target=$1 i
  for i in "${!STEP_IDS[@]}"; do
    if [[ ${STEP_IDS[$i]} == "$target" ]]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

step() {
  local id=$1 label=$2 cmd=$3
  shift 3

  local deps=""
  if [[ ${1:-} == "after" ]]; then
    shift
    local dep_id dep_idx
    for dep_id in "$@"; do
      dep_idx=$(_step_id_to_index "$dep_id") || {
        printf 'step %s: unknown dependency "%s"\n' "$id" "$dep_id" >&2
        exit 1
      }
      deps+="${deps:+ }${dep_idx}"
    done
  fi

  STEP_IDS+=("$id")
  STEP_LABELS+=("$label")
  STEP_CMDS+=("$cmd")
  STEP_DEPS+=("$deps")
  STEP_STATES+=("pending")
  STEP_START_SEC+=(0)
  STEP_ELAPSED+=(0)
  STEP_MESSAGES+=("")
  STEP_PIDS+=("")
  STEP_MSG_FILES+=("")
}

# ── Execution engine ────────────────────────────────────────────────

_deps_satisfied() {
  local idx=$1
  local deps=${STEP_DEPS[$idx]}
  [[ -z $deps ]] && return 0
  local dep_idx
  for dep_idx in $deps; do
    case ${STEP_STATES[$dep_idx]} in
    installed | ok | skipped | warn | needed | current) ;;
    *) return 1 ;;
    esac
  done
  return 0
}

_deps_failed() {
  local idx=$1
  local deps=${STEP_DEPS[$idx]}
  [[ -z $deps ]] && return 1
  local dep_idx
  for dep_idx in $deps; do
    case ${STEP_STATES[$dep_idx]} in
    failed | blocked) return 0 ;;
    esac
  done
  return 1
}

_launch_step() {
  local i=$1
  STEP_MSG_FILES[$i]=$(mktemp)
  STEP_STATES[$i]="running"
  STEP_START_SEC[$i]=$SECONDS
  local log_target="/dev/null"
  if [[ -n ${LOG_DIR:-} ]]; then
    log_target="${LOG_DIR}/${STEP_IDS[$i]}.log"
  fi
  eval "${STEP_CMDS[$i]}" 3>"${STEP_MSG_FILES[$i]}" >>"$log_target" 2>&1 &
  STEP_PIDS[$i]=$!
}

_collect_step() {
  local i=$1 rc=0
  wait "${STEP_PIDS[$i]}" || rc=$?
  STEP_PIDS[$i]=""
  STEP_ELAPSED[$i]=$((SECONDS - STEP_START_SEC[i]))

  if [[ -s ${STEP_MSG_FILES[$i]} ]]; then
    STEP_MESSAGES[$i]=$(<"${STEP_MSG_FILES[$i]}")
  fi
  rm -f "${STEP_MSG_FILES[$i]}"
  STEP_MSG_FILES[$i]=""

  case $rc in
  0) STEP_STATES[$i]="installed" ;;
  2) STEP_STATES[$i]="ok" ;;
  3) STEP_STATES[$i]="skipped" ;;
  4) STEP_STATES[$i]="warn" ;;
  *) STEP_STATES[$i]="failed" ;;
  esac
}

_collect_step_dry() {
  local i=$1 rc=0
  wait "${STEP_PIDS[$i]}" || rc=$?
  STEP_PIDS[$i]=""
  STEP_ELAPSED[$i]=$((SECONDS - STEP_START_SEC[i]))

  if [[ -s ${STEP_MSG_FILES[$i]} ]]; then
    STEP_MESSAGES[$i]=$(<"${STEP_MSG_FILES[$i]}")
  fi
  rm -f "${STEP_MSG_FILES[$i]}"
  STEP_MSG_FILES[$i]=""

  case $rc in
  0) STEP_STATES[$i]="needed" ;;
  2) STEP_STATES[$i]="current" ;;
  3) STEP_STATES[$i]="skipped" ;;
  4) STEP_STATES[$i]="warn" ;;
  *) STEP_STATES[$i]="failed" ;;
  esac
}

_propagate_blocked() {
  local changed=1
  while ((changed)); do
    changed=0
    local i
    for i in "${!STEP_STATES[@]}"; do
      if [[ ${STEP_STATES[$i]} == "pending" ]] && _deps_failed "$i"; then
        STEP_STATES[$i]="blocked"
        changed=1
      fi
    done
  done
}

run() {
  _RUN_START=$SECONDS

  if [[ $FLAG_QUIET == false ]]; then
    if [[ $IS_TTY == true ]]; then
      tput civis 2>/dev/null || true
      render_init
    else
      _plain_init
    fi
  fi

  local i
  for i in "${!STEP_CMDS[@]}"; do
    if [[ -z ${STEP_DEPS[$i]} ]]; then
      _launch_step "$i"
    fi
  done

  local frame_idx=0
  while true; do
    for i in "${!STEP_PIDS[@]}"; do
      [[ -z ${STEP_PIDS[$i]} ]] && continue
      if ! kill -0 "${STEP_PIDS[$i]}" 2>/dev/null; then
        _collect_step "$i"
        [[ $FLAG_QUIET == false ]] && [[ $IS_TTY == false ]] && _plain_emit "$i"
      fi
    done

    _propagate_blocked

    if [[ $FLAG_QUIET == false ]] && [[ $IS_TTY == false ]]; then
      for i in "${!STEP_STATES[@]}"; do
        if [[ ${STEP_STATES[$i]} == "blocked" && -z ${_PLAIN_EMITTED[$i]:-} ]]; then
          _plain_emit "$i"
          _PLAIN_EMITTED[$i]=1
        fi
      done
    fi

    for i in "${!STEP_STATES[@]}"; do
      if [[ ${STEP_STATES[$i]} == "pending" ]] && _deps_satisfied "$i"; then
        _launch_step "$i"
      fi
    done

    if [[ $FLAG_QUIET == false ]] && [[ $IS_TTY == true ]]; then
      render_update "${FRAMES[$frame_idx]}"
      frame_idx=$(((frame_idx + 1) % ${#FRAMES[@]}))
    fi

    local any_active=0
    for i in "${!STEP_STATES[@]}"; do
      case ${STEP_STATES[$i]} in
      running | pending)
        any_active=1
        break
        ;;
      esac
    done
    ((any_active)) || break

    sleep "$FRAME_INTERVAL"
  done

  if [[ $FLAG_QUIET == false ]]; then
    if [[ $IS_TTY == true ]]; then
      printf '\n'
      _report
      tput cnorm 2>/dev/null || true
    else
      _plain_summary
      _plain_report
    fi
  fi
}

run_dry() {
  _RUN_START=$SECONDS

  if [[ $FLAG_QUIET == false ]]; then
    if [[ $IS_TTY == true ]]; then
      tput civis 2>/dev/null || true
      render_init
    else
      _plain_init
    fi
  fi

  local i
  for i in "${!STEP_CMDS[@]}"; do
    if [[ -z ${STEP_DEPS[$i]} ]]; then
      _launch_step "$i"
    fi
  done

  local frame_idx=0
  while true; do
    for i in "${!STEP_PIDS[@]}"; do
      [[ -z ${STEP_PIDS[$i]} ]] && continue
      if ! kill -0 "${STEP_PIDS[$i]}" 2>/dev/null; then
        _collect_step_dry "$i"
        [[ $FLAG_QUIET == false ]] && [[ $IS_TTY == false ]] && _plain_emit "$i"
      fi
    done

    _propagate_blocked

    if [[ $FLAG_QUIET == false ]] && [[ $IS_TTY == false ]]; then
      for i in "${!STEP_STATES[@]}"; do
        if [[ ${STEP_STATES[$i]} == "blocked" && -z ${_PLAIN_EMITTED[$i]:-} ]]; then
          _plain_emit "$i"
          _PLAIN_EMITTED[$i]=1
        fi
      done
    fi

    for i in "${!STEP_STATES[@]}"; do
      if [[ ${STEP_STATES[$i]} == "pending" ]] && _deps_satisfied "$i"; then
        _launch_step "$i"
      fi
    done

    if [[ $FLAG_QUIET == false ]] && [[ $IS_TTY == true ]]; then
      render_update "${FRAMES[$frame_idx]}"
      frame_idx=$(((frame_idx + 1) % ${#FRAMES[@]}))
    fi

    local any_active=0
    for i in "${!STEP_STATES[@]}"; do
      case ${STEP_STATES[$i]} in
      running | pending)
        any_active=1
        break
        ;;
      esac
    done
    ((any_active)) || break

    sleep "$FRAME_INTERVAL"
  done

  if [[ $FLAG_QUIET == false ]]; then
    if [[ $IS_TTY == true ]]; then
      printf '\n'
      _report_dry
      tput cnorm 2>/dev/null || true
    else
      _plain_summary
      _plain_report
    fi
  fi
}

# ── TTY rendering ───────────────────────────────────────────────────

BAR_WIDTH=76
FILLED_BARS=()
EMPTY_BARS=()

_init_bars() {
  _detect_width
  BAR_WIDTH=$((TERM_WIDTH - 4))
  if ((BAR_WIDTH < 20)); then BAR_WIDTH=20; fi

  FILLED_BARS=()
  EMPTY_BARS=()
  local f="" e=""
  local b
  for ((b = 0; b <= BAR_WIDTH; b++)); do
    FILLED_BARS+=("$f")
    f+="━"
  done
  e=""
  for ((b = BAR_WIDTH; b >= 0; b--)); do
    EMPTY_BARS+=("$e")
    e+="─"
  done
}

total_lines=0
_MAX_LABEL_WIDTH=0

render_init() {
  _init_bars
  _MAX_LABEL_WIDTH=0
  local l
  for l in "${STEP_LABELS[@]}"; do
    if ((${#l} > _MAX_LABEL_WIDTH)); then _MAX_LABEL_WIDTH=${#l}; fi
  done
  total_lines=$((${#STEP_LABELS[@]} + 2))
  local i
  for i in "${!STEP_LABELS[@]}"; do
    _render_step "$i" ""
    printf '\n'
  done
  printf '\n'
  _render_footer
  printf '\n'
}

render_update() {
  printf '\033[%dA' "$total_lines"
  local i
  for i in "${!STEP_LABELS[@]}"; do
    _render_step "$i" "$1"
    printf '%s\n' "$CLR"
  done
  printf '%s\n' "$CLR"
  _render_footer
  printf '%s\n' "$CLR"
}

_render_step() {
  local idx=$1 frame=$2
  local state=${STEP_STATES[$idx]}
  local label=${STEP_LABELS[$idx]}
  local msg=${STEP_MESSAGES[$idx]}
  local pad=$((_MAX_LABEL_WIDTH - ${#label}))
  local secs

  case $state in
  pending)
    printf '  %s○  %s%*s%s' "$GRAY$DIM" "$label" "$pad" "" "$RST"
    ;;
  running)
    secs=$((SECONDS - STEP_START_SEC[idx]))
    printf '  %s%s%s  %s%s%s%*s' \
      "$CYAN$BOLD" "$frame" "$RST" \
      "$WHITE$BOLD" "$label" "$RST" "$pad" ""
    _print_detail "$GRAY" "$secs" "$msg"
    ;;
  installed)
    secs=${STEP_ELAPSED[$idx]}
    printf '  %s✔%s  %s%s%s%*s' \
      "$GREEN$BOLD" "$RST" \
      "$GREEN$BOLD" "$label" "$RST" "$pad" ""
    _print_detail "$GREEN" "$secs" "$msg"
    ;;
  ok)
    secs=${STEP_ELAPSED[$idx]}
    printf '  %s●%s  %s%s%s%*s' \
      "$GREEN" "$RST" \
      "$GREEN" "$label" "$RST" "$pad" ""
    _print_detail "$GRAY" "$secs" "$msg"
    ;;
  skipped)
    printf '  %s○  %s%*s' "$GRAY$DIM" "$label" "$pad" ""
    if [[ -n $msg ]]; then
      printf '%5s  %s' "" "$msg"
    fi
    printf '%s' "$RST"
    ;;
  warn)
    secs=${STEP_ELAPSED[$idx]}
    printf '  %s▲%s  %s%s%s%*s' \
      "$YELLOW" "$RST" \
      "$YELLOW" "$label" "$RST" "$pad" ""
    _print_detail "$YELLOW" "$secs" "$msg"
    ;;
  failed)
    secs=${STEP_ELAPSED[$idx]}
    printf '  %s✖%s  %s%s%s%*s' \
      "$RED$BOLD" "$RST" \
      "$RED$BOLD" "$label" "$RST" "$pad" ""
    _print_detail "$RED" "$secs" "$msg"
    ;;
  blocked)
    printf '  %s⊘  %s%*s' "$RED$DIM" "$label" "$pad" ""
    if [[ -n $msg ]]; then
      printf '%5s  %s' "" "$msg"
    fi
    printf '%s' "$RST"
    ;;
  needed)
    printf '  %s◆%s  %s%s%s%*s' \
      "$YELLOW" "$RST" \
      "$YELLOW" "$label" "$RST" "$pad" ""
    if [[ -n $msg ]]; then
      printf '%5s  %s%s%s' "" "$YELLOW$DIM" "$msg" "$RST"
    fi
    ;;
  current)
    printf '  %s●%s  %s%s%s%*s' \
      "$GREEN" "$RST" \
      "$GREEN" "$label" "$RST" "$pad" ""
    if [[ -n $msg ]]; then
      printf '%5s  %s%s%s' "" "$GRAY" "$msg" "$RST"
    fi
    ;;
  esac
}

_print_detail() {
  local color=$1 secs=$2 msg=$3
  local time_str
  if ((secs < 60)); then
    time_str="${secs}s"
  else
    printf -v time_str '%dm%02ds' $((secs / 60)) $((secs % 60))
  fi
  printf '  %s%3s%s' "$color" "$time_str" "$RST"
  if [[ -n $msg ]]; then
    printf '  %s%s%s' "$color" "$msg" "$RST"
  fi
}

_render_footer() {
  local total=${#STEP_LABELS[@]}
  local n_installed=0 n_ok=0 n_skipped=0 n_warn=0 n_failed=0 n_running=0 n_pending=0
  local n_needed=0 n_current=0 n_blocked=0

  local s
  for s in "${STEP_STATES[@]}"; do
    case $s in
    installed) ((n_installed++)) ;;
    ok) ((n_ok++)) ;;
    skipped) ((n_skipped++)) ;;
    warn) ((n_warn++)) ;;
    failed) ((n_failed++)) ;;
    running) ((n_running++)) ;;
    needed) ((n_needed++)) ;;
    current) ((n_current++)) ;;
    blocked) ((n_blocked++)) ;;
    *) ((n_pending++)) ;;
    esac
  done

  local completed=$((n_installed + n_ok + n_skipped + n_warn + n_failed + n_blocked + n_needed + n_current))

  local bar_color=$GREEN
  ((n_warn > 0)) && bar_color=$YELLOW
  ((n_failed > 0)) && bar_color=$RED
  ((n_running > 0)) && bar_color=$CYAN

  local pct=0
  ((total > 0)) && pct=$((completed * 100 / total))

  # Build uncolored suffix to measure width for bar sizing
  local suffix_parts="" sep=""
  if ((n_installed > 0)); then
    suffix_parts+="${sep}${n_installed} installed"
    sep=", "
  fi
  if ((n_ok > 0)); then
    suffix_parts+="${sep}${n_ok} ok"
    sep=", "
  fi
  if ((n_needed > 0)); then
    suffix_parts+="${sep}${n_needed} needed"
    sep=", "
  fi
  if ((n_current > 0)); then
    suffix_parts+="${sep}${n_current} current"
    sep=", "
  fi
  if ((n_skipped > 0)); then
    suffix_parts+="${sep}${n_skipped} skipped"
    sep=", "
  fi
  if ((n_warn > 0)); then
    suffix_parts+="${sep}${n_warn} warn"
    sep=", "
  fi
  if ((n_failed > 0)); then
    suffix_parts+="${sep}${n_failed} failed"
    sep=", "
  fi
  if ((n_blocked > 0)); then
    suffix_parts+="${sep}${n_blocked} blocked"
    sep=", "
  fi
  if ((n_running > 0)); then
    suffix_parts+="${sep}${n_running} running"
    sep=", "
  fi
  if ((n_pending > 0)); then
    suffix_parts+="${sep}${n_pending} pending"
    sep=", "
  fi

  local pct_str="${pct}%"
  local suffix_plain="  ${pct_str}  (${suffix_parts})"
  local suffix_len=${#suffix_plain}

  local bar_w=$((TERM_WIDTH - 2 - suffix_len))
  if ((bar_w < 10)); then bar_w=10; fi
  if ((bar_w > BAR_WIDTH)); then bar_w=$BAR_WIDTH; fi

  local filled=0
  ((total > 0)) && filled=$((completed * bar_w / total))
  local empty=$((bar_w - filled))

  printf '  %s%s%s%s%s' \
    "$bar_color" "${FILLED_BARS[$filled]}" "$RST" \
    "$GRAY" "${EMPTY_BARS[$empty]}"

  printf '  %s%s%s' "$WHITE$BOLD" "$pct_str" "$RST"

  printf '  %s(' "$GRAY"
  sep=""
  if ((n_installed > 0)); then
    printf '%s%s%d installed%s' "$sep" "$GREEN$BOLD" "$n_installed" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_ok > 0)); then
    printf '%s%s%d ok%s' "$sep" "$GREEN" "$n_ok" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_needed > 0)); then
    printf '%s%s%d needed%s' "$sep" "$YELLOW" "$n_needed" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_current > 0)); then
    printf '%s%s%d current%s' "$sep" "$GREEN" "$n_current" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_skipped > 0)); then
    printf '%s%s%d skipped%s' "$sep" "$GRAY" "$n_skipped" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_warn > 0)); then
    printf '%s%s%d warn%s' "$sep" "$YELLOW" "$n_warn" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_failed > 0)); then
    printf '%s%s%d failed%s' "$sep" "$RED$BOLD" "$n_failed" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_blocked > 0)); then
    printf '%s%s%d blocked%s' "$sep" "$RED$DIM" "$n_blocked" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_running > 0)); then
    printf '%s%s%d running%s' "$sep" "$CYAN" "$n_running" "$RST"
    sep="${GRAY}, "
  fi
  if ((n_pending > 0)); then printf '%s%s%d pending%s' "$sep" "$GRAY$DIM" "$n_pending" "$RST"; fi
  printf '%s)%s' "$GRAY" "$RST"
}

# ── Plain-text output (non-TTY) ─────────────────────────────────────

_plain_icon() {
  case $1 in
  installed) echo "OK" ;;
  ok) echo "OK" ;;
  skipped) echo "--" ;;
  warn) echo "!!" ;;
  failed) echo "FAIL" ;;
  blocked) echo "SKIP" ;;
  needed) echo "NEED" ;;
  current) echo "OK" ;;
  esac
}

_PLAIN_LABEL_WIDTH=0

_plain_init() {
  _PLAIN_LABEL_WIDTH=0
  local l
  for l in "${STEP_LABELS[@]}"; do
    if ((${#l} > _PLAIN_LABEL_WIDTH)); then _PLAIN_LABEL_WIDTH=${#l}; fi
  done
}

_plain_emit() {
  local i=$1
  local state=${STEP_STATES[$i]}
  local label=${STEP_LABELS[$i]}
  local msg=${STEP_MESSAGES[$i]}
  local icon
  icon=$(_plain_icon "$state")
  if [[ -n $msg ]]; then
    printf '  %-4s  %-*s  %s\n' "$icon" "$_PLAIN_LABEL_WIDTH" "$label" "$msg"
  else
    printf '  %-4s  %s\n' "$icon" "$label"
  fi
}

_plain_summary() {
  local total=${#STEP_LABELS[@]}
  local n_installed=0 n_ok=0 n_skipped=0 n_warn=0 n_failed=0 n_blocked=0
  local n_needed=0 n_current=0

  local s
  for s in "${STEP_STATES[@]}"; do
    case $s in
    installed) ((n_installed++)) ;;
    ok) ((n_ok++)) ;;
    skipped) ((n_skipped++)) ;;
    warn) ((n_warn++)) ;;
    failed) ((n_failed++)) ;;
    blocked) ((n_blocked++)) ;;
    needed) ((n_needed++)) ;;
    current) ((n_current++)) ;;
    esac
  done

  local parts=()
  ((n_installed > 0)) && parts+=("${n_installed} installed")
  ((n_ok > 0)) && parts+=("${n_ok} ok")
  ((n_needed > 0)) && parts+=("${n_needed} needed")
  ((n_current > 0)) && parts+=("${n_current} current")
  ((n_skipped > 0)) && parts+=("${n_skipped} skipped")
  ((n_warn > 0)) && parts+=("${n_warn} warn")
  ((n_failed > 0)) && parts+=("${n_failed} failed")
  ((n_blocked > 0)) && parts+=("${n_blocked} blocked")

  local result="" p
  for p in "${parts[@]}"; do
    result+="${result:+, }${p}"
  done
  printf '\n  Done: %s (of %d)\n' "$result" "$total"
}

# ── Header ──────────────────────────────────────────────────────────

_print_header() {
  local title=$1 color=${2:-$CYAN}
  _detect_width
  printf '\n'
  if [[ $IS_TTY == true ]]; then
    local trail_len=$((TERM_WIDTH - 6 - ${#title}))
    if ((trail_len < 2)); then trail_len=2; fi
    local trail="" t
    for ((t = 0; t < trail_len; t++)); do trail+="━"; done
    printf '  %s%s━━ %s %s%s\n' "$color" "$BOLD" "$title" "$trail" "$RST"
  else
    printf '  == %s ==\n' "$title"
  fi
  printf '\n'
}

# ── Completion reports ──────────────────────────────────────────────

_RUN_START=0

_format_total_elapsed() {
  local secs=$1
  if ((secs < 60)); then
    printf '%ds' "$secs"
  else
    printf '%dm%02ds' $((secs / 60)) $((secs % 60))
  fi
}

_report_step() {
  local icon=$1 icon_color=$2 label_color=$3 detail_color=$4
  local secs=$5 msg=$6
  local label="dotfiles"
  local pad=$((_MAX_LABEL_WIDTH - ${#label}))
  printf '  %s%s%s  %s%s%s%*s' \
    "$icon_color" "$icon" "$RST" \
    "$label_color" "$label" "$RST" "$pad" ""
  _print_detail "$detail_color" "$secs" "$msg"
  printf '\n'
}

_report() {
  local secs=$((SECONDS - _RUN_START))
  local n_warn=0 n_failed=0 n_blocked=0
  local s
  for s in "${STEP_STATES[@]}"; do
    case $s in
    warn) ((n_warn++)) ;;
    failed) ((n_failed++)) ;;
    blocked) ((n_blocked++)) ;;
    esac
  done

  if ((n_failed > 0)); then
    _report_tty_failure "$secs" "$n_failed" "$n_blocked" "$n_warn"
  elif ((n_warn > 0)); then
    _report_tty_warn "$secs" "$n_warn"
  else
    _report_tty_success "$secs"
  fi
}

_report_tty_success() {
  local secs=$1
  _report_step "✔" "$GREEN$BOLD" "$GREEN$BOLD" "$GREEN" "$secs" ""
  printf '\n'
}

_report_tty_warn() {
  local secs=$1 n_warn=$2
  local wlabel="warning"
  ((n_warn > 1)) && wlabel="warnings"
  _report_step "✔" "$GREEN$BOLD" "$GREEN$BOLD" "$GREEN" "$secs" "$n_warn $wlabel"
  local i
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "warn" ]]; then
      _render_step "$i" ""
      printf '\n'
      if [[ -n ${LOG_DIR:-} ]]; then
        printf '     %s%s/%s.log%s\n' "$GRAY" "$LOG_DIR" "${STEP_IDS[$i]}" "$RST"
      fi
    fi
  done
  printf '\n'
}

_report_tty_failure() {
  local secs=$1 n_failed=$2 n_blocked=$3 n_warn=$4

  local detail="${n_failed} failed"
  ((n_blocked > 0)) && detail+=", ${n_blocked} blocked"
  ((n_warn > 0)) && detail+=", ${n_warn} warn"
  _report_step "✖" "$RED$BOLD" "$RED$BOLD" "$RED" "$secs" "$detail"

  local i
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "failed" ]]; then
      _render_step "$i" ""
      printf '\n'
      if [[ -n ${LOG_DIR:-} ]]; then
        printf '     %s%s/%s.log%s\n' "$GRAY" "$LOG_DIR" "${STEP_IDS[$i]}" "$RST"
      fi
    fi
  done
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "blocked" ]]; then
      local blocker="" dep_idx
      for dep_idx in ${STEP_DEPS[$i]}; do
        case ${STEP_STATES[$dep_idx]} in
        failed | blocked)
          blocker=${STEP_LABELS[$dep_idx]}
          break
          ;;
        esac
      done
      STEP_MESSAGES[$i]="blocked by $blocker"
      _render_step "$i" ""
      printf '\n'
    fi
  done
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "warn" ]]; then
      _render_step "$i" ""
      printf '\n'
    fi
  done

  printf '\n'
  if [[ -n $_ORIGINAL_CMD ]]; then
    local rerun_cmd=$_ORIGINAL_CMD
    if [[ $rerun_cmd != *--force* ]] && [[ $rerun_cmd != *-f\ * ]] && [[ $rerun_cmd != *-f ]]; then
      rerun_cmd+=" --force"
    fi
    printf '  %srerun%s  %s\n' "$WHITE$BOLD" "$RST" "$rerun_cmd"
  fi
  printf '\n'
}

_report_dry() {
  local n_needed=0 n_current=0 n_skipped=0 n_failed=0
  local s
  for s in "${STEP_STATES[@]}"; do
    case $s in
    needed) ((n_needed++)) ;;
    current) ((n_current++)) ;;
    skipped) ((n_skipped++)) ;;
    failed) ((n_failed++)) ;;
    esac
  done

  if ((n_failed > 0)); then
    printf '\n  %s✖ dry-run check failed%s\n\n' "$RED$BOLD" "$RST"
    local i
    for i in "${!STEP_STATES[@]}"; do
      if [[ ${STEP_STATES[$i]} == "failed" ]]; then
        printf '  %s✖ %s%s  %s\n' \
          "$RED$BOLD" "${STEP_LABELS[$i]}" "$RST" "${STEP_MESSAGES[$i]}"
      fi
    done
  else
    local parts="" sep=""
    ((n_needed > 0)) && parts+="${sep}${n_needed} to install" && sep=", "
    ((n_current > 0)) && parts+="${sep}${n_current} current" && sep=", "
    ((n_skipped > 0)) && parts+="${sep}${n_skipped} skipped" && sep=", "
    printf '\n  %s%s%s\n' "$CYAN" "$parts" "$RST"
  fi

  if [[ -n $_ORIGINAL_CMD ]] && ((n_failed == 0)); then
    local run_cmd=$_ORIGINAL_CMD
    run_cmd=${run_cmd// --dry-run/}
    run_cmd=${run_cmd// -n / }
    run_cmd=${run_cmd%% }
    printf '\n  %srun%s   %s\n' "$WHITE$BOLD" "$RST" "$run_cmd"
  fi
  printf '\n'
}

# ── Non-TTY report (all modes) ──────────────────────────────────────

_plain_report() {
  local elapsed
  elapsed=$(_format_total_elapsed $((SECONDS - _RUN_START)))

  local n_installed=0 n_ok=0 n_skipped=0 n_warn=0 n_failed=0 n_blocked=0
  local n_needed=0 n_current=0
  local s
  for s in "${STEP_STATES[@]}"; do
    case $s in
    installed) ((n_installed++)) ;;
    ok) ((n_ok++)) ;;
    skipped) ((n_skipped++)) ;;
    warn) ((n_warn++)) ;;
    failed) ((n_failed++)) ;;
    blocked) ((n_blocked++)) ;;
    needed) ((n_needed++)) ;;
    current) ((n_current++)) ;;
    esac
  done

  printf '\n'
  if ((n_failed > 0)); then
    printf 'status: failed\n'
  elif ((n_needed > 0)); then
    printf 'status: dry-run\n'
  elif ((n_warn > 0)); then
    printf 'status: ok (with warnings)\n'
  else
    printf 'status: ok\n'
  fi
  printf 'elapsed: %s\n' "$elapsed"

  local i
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "failed" ]]; then
      printf 'failed: %s (%s)\n' "${STEP_LABELS[$i]}" "${STEP_MESSAGES[$i]}"
      if [[ -n ${LOG_DIR:-} ]]; then
        printf 'log_%s: %s/%s.log\n' "${STEP_IDS[$i]}" "$LOG_DIR" "${STEP_IDS[$i]}"
      fi
    fi
  done

  local blocked_list=""
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "blocked" ]]; then
      blocked_list+="${blocked_list:+, }${STEP_LABELS[$i]}"
    fi
  done
  [[ -n $blocked_list ]] && printf 'blocked: %s\n' "$blocked_list"

  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "warn" ]]; then
      printf 'warn: %s (%s)\n' "${STEP_LABELS[$i]}" "${STEP_MESSAGES[$i]}"
      if [[ -n ${LOG_DIR:-} ]]; then
        printf 'log_%s: %s/%s.log\n' "${STEP_IDS[$i]}" "$LOG_DIR" "${STEP_IDS[$i]}"
      fi
    fi
  done

  local needed_list=""
  for i in "${!STEP_STATES[@]}"; do
    if [[ ${STEP_STATES[$i]} == "needed" ]]; then
      needed_list+="${needed_list:+, }${STEP_LABELS[$i]}"
    fi
  done
  [[ -n $needed_list ]] && printf 'needed: %s\n' "$needed_list"

  if [[ -n ${LOG_DIR:-} ]]; then
    printf 'log_dir: %s\n' "$LOG_DIR"
  fi
  if [[ -n $_ORIGINAL_CMD ]]; then
    printf 'command: %s\n' "$_ORIGINAL_CMD"
    if ((n_failed > 0)); then
      local rerun_cmd=$_ORIGINAL_CMD
      if [[ $rerun_cmd != *--force* ]] && [[ $rerun_cmd != *-f\ * ]] && [[ $rerun_cmd != *-f ]]; then
        rerun_cmd+=" --force"
      fi
      printf 'rerun: %s\n' "$rerun_cmd"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════════════
# Greeting
# ═══════════════════════════════════════════════════════════════════════

_LABEL_W=14

_banner() {
  _detect_width

  local box_inner=40
  local box_outer=$((box_inner + 2))
  local pad=$(((TERM_WIDTH - box_outer) / 2))
  ((pad < 2)) && pad=2
  local indent
  printf -v indent '%*s' "$pad" ""

  local hline spacer
  hline=$(_repeat "─" "$box_inner")
  spacer=$(_repeat " " "$box_inner")

  local tl=$(((box_inner - 29) / 2))
  local tr=$((box_inner - 29 - tl))

  local title=""
  title+="${CYAN}${BOLD}d ${DIM}·${RST}${CYAN}${BOLD} o ${DIM}·${RST}"
  title+="${CYAN}${BOLD} t ${DIM}·${RST}${CYAN}${BOLD} f ${DIM}·${RST}"
  title+="${GREEN}${BOLD} i ${DIM}·${RST}${GREEN}${BOLD} l ${DIM}·${RST}"
  title+="${GREEN}${BOLD} e ${DIM}·${RST}${GREEN}${BOLD} s${RST}"

  local gl=$(((box_inner - 27) / 2))
  local gr=$((box_inner - 27 - gl))

  local lines=()
  lines+=("")
  lines+=("${indent}${GRAY}╭${hline}╮${RST}")
  lines+=("${indent}${GRAY}│${spacer}│${RST}")
  lines+=("${indent}${GRAY}│${RST}$(_repeat ' ' "$tl")${title}$(_repeat ' ' "$tr")${GRAY}│${RST}")
  lines+=("${indent}${GRAY}│${RST}$(_repeat ' ' "$gl")${DIM}ivy's developer environment${RST}$(_repeat ' ' "$gr")${GRAY}│${RST}")
  lines+=("${indent}${GRAY}│${spacer}│${RST}")
  lines+=("${indent}${GRAY}╰${hline}╯${RST}")
  lines+=("")

  if [[ $IS_TTY == true ]]; then
    tput civis 2>/dev/null || true
    local line
    for line in "${lines[@]}"; do
      printf '%s\n' "$line"
      sleep 0.06
    done
    tput cnorm 2>/dev/null || true
  else
    local line
    for line in "${lines[@]}"; do
      printf '%s\n' "$line"
    done
  fi
}

_prompt_text() {
  local label=$1 default=${2:-}

  local hint=""
  [[ -n $default ]] && hint=" ${GRAY}[${default}]${RST}"

  printf '  %s◆%s  %s%s%s%s: ' "$CYAN" "$RST" "$WHITE" "$label" "$RST" "$hint"

  local input
  read -r input </dev/tty
  [[ -z $input ]] && input=$default

  if [[ $IS_TTY == true ]]; then
    printf '\033[1A\r\033[K'
  fi
  printf '  %s●%s  %-*s %s%s%s\n' \
    "$GREEN" "$RST" "$_LABEL_W" "$label" "$WHITE" "$input" "$RST"

  REPLY=$input
}

_prompt_yn() {
  local label=$1 default=${2:-n}

  local hint
  [[ $default == y ]] && hint="Y/n" || hint="y/N"

  printf '  %s◆%s  %s%s%s %s[%s]%s ' \
    "$CYAN" "$RST" "$WHITE" "$label" "$RST" "$GRAY" "$hint" "$RST"

  local value=""
  while [[ -z $value ]]; do
    local ch
    IFS= read -rsn1 ch </dev/tty
    case $ch in
    [Yy]) value="yes" ;;
    [Nn]) value="no" ;;
    "") [[ $default == y ]] && value="yes" || value="no" ;; # Enter
    esac
  done

  if [[ $IS_TTY == true ]]; then
    printf '\r\033[K'
  else
    printf '\n'
  fi
  printf '  %s●%s  %-*s %s%s%s\n' \
    "$GREEN" "$RST" "$_LABEL_W" "$label" "$WHITE" "$value" "$RST"

  REPLY=$value
}

_prompt_confirm() {
  local label=$1 hint=$2

  printf '  %s◆%s  %s%s%s  %s\n' "$CYAN" "$RST" "$WHITE" "$label" "$RST" "$hint"
  printf '     ▸ '

  local input
  read -r input </dev/tty

  if [[ $IS_TTY == true ]]; then
    printf '\033[1A\r\033[K\033[1A\r\033[K'
  fi

  if [[ $input == "yes" ]]; then
    printf '  %s●%s  %-*s %sconfirmed%s\n' \
      "$GREEN" "$RST" "$_LABEL_W" "$label" "$GREEN" "$RST"
    return 0
  else
    printf '  %s✖%s  %-*s %saborted%s\n' \
      "$RED" "$RST" "$_LABEL_W" "$label" "$RED" "$RST"
    return 1
  fi
}

_needs_sudo() {
  # macOS: Homebrew initial install needs root
  [[ $(uname -s) == Darwin ]] && return 0
  return 1
}

_prompt_sudo() {
  local label="Password"
  local hint="${GRAY}Homebrew install requires sudo${RST}"

  # Already root — nothing to do
  ((EUID == 0)) && return 0

  # Credentials already cached — show as pre-filled
  if sudo -vn 2>/dev/null; then
    printf '  %s●%s  %-*s %scached%s\n' \
      "$GREEN" "$RST" "$_LABEL_W" "$label" "$DIM" "$RST"
    return 0
  fi

  # Show prompt in our style, then hand off to sudo for secure entry.
  # sudo -p sets the prompt text; sudo reads from /dev/tty with echo disabled.
  printf '  %s◆%s  %s%s%s  %s\n' "$CYAN" "$RST" "$WHITE" "$label" "$RST" "$hint"
  if ! sudo -v -p "     ▸ " </dev/tty; then
    if [[ $IS_TTY == true ]]; then
      printf '\033[1A\r\033[K\033[1A\r\033[K'
    fi
    printf '  %s✖%s  %-*s %sfailed%s\n' \
      "$RED" "$RST" "$_LABEL_W" "$label" "$RED" "$RST"
    return 1
  fi

  # Replace the prompt + sudo input lines with styled confirmation
  if [[ $IS_TTY == true ]]; then
    printf '\033[1A\r\033[K\033[1A\r\033[K'
  fi
  printf '  %s●%s  %-*s %s✓%s\n' \
    "$GREEN" "$RST" "$_LABEL_W" "$label" "$GREEN" "$RST"
}

_acquire_sudo_if_needed() {
  # Silent sudo acquisition for non-interactive mode (quiet, all flags provided).
  # In interactive mode, _greeting handles this with a styled prompt.
  [[ $FLAG_DRY_RUN == true ]] && return 0
  _needs_sudo || return 0
  ((EUID == 0)) && return 0
  sudo -vn 2>/dev/null && return 0
  sudo -v </dev/tty 2>/dev/null || return 1
}

_greeting() {
  # Skip in quiet mode
  if [[ $FLAG_QUIET == true ]]; then return; fi

  # Skip if all identity values provided via flags
  if [[ -n $GIT_USER_NAME && -n $GIT_USER_EMAIL && -n $FLAG_BEDROCK ]]; then return; fi

  # Compute defaults for unprovided values
  local default_name="" default_email=""

  if [[ -z $GIT_USER_NAME ]]; then
    default_name=$(git config user.name 2>/dev/null || true)
    if [[ -z $default_name ]]; then
      default_name=$(prefill_name 2>/dev/null || true)
    fi
  fi

  if [[ -z $GIT_USER_EMAIL ]]; then
    default_email=$(git config user.email 2>/dev/null || true)
    if [[ -z $default_email ]]; then
      default_email=$(prefill_email 2>/dev/null || true)
    fi
  fi

  _banner

  # Nuke confirmation — require typing "yes" (--nuke --force skips)
  if [[ $FLAG_NUKE == true ]]; then
    printf '\n'
    printf '  %s%s⚠  --nuke will destroy and rebuild everything:%s\n' "$YELLOW" "$BOLD" "$RST"
    printf '  %s     •  Uninstall cosign, mise, chezmoi, and Claude Code%s\n' "$DIM" "$RST"
    printf '  %s     •  Delete chezmoi config and persistent state%s\n' "$DIM" "$RST"
    printf '  %s     •  Reinstall all tools from scratch%s\n' "$DIM" "$RST"
    printf '  %s     •  Re-run every setup script as if this were a fresh machine%s\n' "$DIM" "$RST"
    printf '\n'
    if [[ $FLAG_EXPLICIT_FORCE == true ]]; then
      printf '  %s●%s  %-*s %sconfirmed (--force)%s\n' \
        "$YELLOW" "$RST" "$_LABEL_W" "Nuke" "$YELLOW" "$RST"
    else
      _prompt_confirm "Nuke" "${RED}type \"yes\" to continue${RST}" ||
        exit 0
    fi
  fi

  # Prompt for or display each value
  if [[ -z $GIT_USER_NAME ]]; then
    _prompt_text "Git name" "$default_name"
    GIT_USER_NAME=$REPLY
  else
    printf '  %s●%s  %-*s %s%s%s\n' \
      "$GREEN" "$RST" "$_LABEL_W" "Git name" "$WHITE" "$GIT_USER_NAME" "$RST"
  fi

  if [[ -z $GIT_USER_EMAIL ]]; then
    _prompt_text "Git email" "$default_email"
    GIT_USER_EMAIL=$REPLY
  else
    printf '  %s●%s  %-*s %s%s%s\n' \
      "$GREEN" "$RST" "$_LABEL_W" "Git email" "$WHITE" "$GIT_USER_EMAIL" "$RST"
  fi

  if [[ -z $FLAG_BEDROCK ]]; then
    _prompt_yn "AWS Bedrock" "n"
    [[ $REPLY == "yes" ]] && FLAG_BEDROCK="true" || FLAG_BEDROCK="false"
  else
    local display
    [[ $FLAG_BEDROCK == "true" ]] && display="yes" || display="no"
    printf '  %s●%s  %-*s %s%s%s\n' \
      "$GREEN" "$RST" "$_LABEL_W" "AWS Bedrock" "$WHITE" "$display" "$RST"
  fi

  # Acquire sudo during greeting so background steps don't prompt on /dev/tty
  if [[ $FLAG_DRY_RUN == false ]] && _needs_sudo; then
    _prompt_sudo || {
      printf '\n%serror:%s Could not obtain sudo credentials\n' "${RED:-}" "${RST:-}" >&2
      exit 1
    }
  fi

  sleep 0.5

  # Hard cut to progress phase
  if [[ $IS_TTY == true ]]; then
    printf '\033[2J\033[H'
  else
    printf '\n'
  fi
}

# ═══════════════════════════════════════════════════════════════════════
# Nuke teardown
# ═══════════════════════════════════════════════════════════════════════

_nuke_emit() {
  local label=$1 detail=$2
  printf '  %s✕%s  %-14s %s%s%s\n' "$RED" "$RST" "$label" "$GRAY" "$detail" "$RST"
}

_nuke_teardown() {
  local os
  os=$(uname -s)

  if [[ $FLAG_QUIET == false ]]; then
    [[ $IS_TTY == true ]] && printf '\033[2J\033[H'
    printf '\n  %s%s⚠  Nuking...%s\n\n' "$RED" "$BOLD" "$RST"
  fi

  # Wipe chezmoi config and persistent state
  local chezmoi_config="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
  if [[ -d $chezmoi_config ]]; then
    rm -rf "$chezmoi_config"
    [[ $FLAG_QUIET == false ]] && _nuke_emit "Chezmoi config" "$chezmoi_config"
  fi

  # Remove Claude Code
  if [[ -d "$HOME/.claude/local" ]]; then
    rm -rf "$HOME/.claude/local"
    [[ $FLAG_QUIET == false ]] && _nuke_emit "Claude Code" "~/.claude/local"
  fi

  # Uninstall brew-managed tools
  if [[ $os == Darwin ]] && [[ $FLAG_NO_PKG_MGR == false ]]; then
    local brew
    brew=$(_find_brew 2>/dev/null) || true
    if [[ -n $brew ]]; then
      eval "$("$brew" shellenv)"
      local tool
      for tool in cosign mise chezmoi; do
        if "$brew" list "$tool" >/dev/null 2>&1; then
          "$brew" uninstall --force "$tool" >/dev/null 2>&1 || true
          [[ $FLAG_QUIET == false ]] && _nuke_emit "$tool" "brew uninstall $tool"
        fi
      done
    fi
  else
    # Linux: remove binaries from BIN_DIR
    local bin
    for bin in cosign chezmoi; do
      if [[ -f "$BIN_DIR/$bin" ]]; then
        rm -f "$BIN_DIR/$bin"
        [[ $FLAG_QUIET == false ]] && _nuke_emit "$bin" "$BIN_DIR/$bin"
      fi
    done
  fi

  if [[ $FLAG_QUIET == false ]]; then
    printf '\n'
    sleep 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════
# Step functions
# ═══════════════════════════════════════════════════════════════════════
#
# Each function runs in a forked subshell (via &). Write status messages
# to fd 3. Exit codes: 0=installed, 2=ok, 3=skipped, 4=warn, other=failed.
# In dry-run mode the engine maps: 0=needed, 2=current, 3=skipped, other=failed.

_step_preflight() {
  local issues=""

  # Download tool
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "no download tool (curl or wget)" >&3
    exit 1
  fi

  # Git
  if ! command -v git >/dev/null 2>&1; then
    echo "git not found" >&3
    exit 1
  fi

  # Valid dotfiles checkout
  if [[ ! -d "$SCRIPT_DIR/home" ]]; then
    echo "not a valid dotfiles checkout (missing home/)" >&3
    exit 1
  fi

  # BIN_DIR writable
  if ! mkdir -p "$BIN_DIR" 2>/dev/null; then
    echo "$BIN_DIR not writable" >&3
    exit 1
  fi

  # Network reachable (warn-only)
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsS --connect-timeout 5 --max-time 10 https://github.com -o /dev/null 2>/dev/null; then
      echo "network unreachable (tools may be cached)" >&3
      exit 4
    fi
  fi

  echo "all checks passed" >&3
  exit 2
}

_step_homebrew() {
  local brew
  brew=$(_find_brew 2>/dev/null) || true

  # Homebrew is a package manager, not a versioned tool — --force applies
  # to tools installed via brew, not to brew itself.
  if [[ -n $brew ]]; then
    local ver
    ver=$("$brew" --version 2>/dev/null | head -1 | sed 's/Homebrew //') || ver="unknown"
    echo "$ver" >&3
    exit 2
  fi

  if [[ $FLAG_DRY_RUN == true ]]; then
    if [[ -n $brew ]]; then
      echo "$("$brew" --version 2>/dev/null | head -1 | sed 's/Homebrew //')" >&3
      exit 2
    fi
    echo "not installed" >&3
    exit 0
  fi

  # Install Homebrew non-interactively (step runs in background, no stdin)
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  brew=$(_find_brew) || {
    echo "installed but not found in PATH" >&3
    exit 1
  }
  local ver
  ver=$("$brew" --version 2>/dev/null | head -1 | sed 's/Homebrew //') || ver="installed"
  echo "$ver" >&3
  exit 0
}

_BREW_LOCK="${TMPDIR:-/tmp}/dotfiles-brew.lock"

# Serialize brew operations — concurrent installs conflict on shared cellar paths
_brew_lock() { while ! mkdir "$_BREW_LOCK" 2>/dev/null; do sleep 0.2; done; }
_brew_unlock() { rmdir "$_BREW_LOCK" 2>/dev/null || true; }

_step_brew_tool() {
  local tool=$1
  local brew
  brew=$(_find_brew) || {
    echo "brew not found" >&3
    exit 1
  }
  eval "$("$brew" shellenv)"

  if [[ $FLAG_FORCE == false ]] && tool_healthy "$tool"; then
    echo "$(tool_version "$tool")" >&3
    exit 2
  fi

  if [[ $FLAG_DRY_RUN == true ]]; then
    if tool_healthy "$tool"; then
      echo "$(tool_version "$tool")" >&3
      exit 2
    fi
    echo "not installed" >&3
    exit 0
  fi

  _brew_lock
  trap '_brew_unlock' EXIT

  # Clean up stale .reinstall keg dirs left by prior interrupted reinstalls
  local cellar
  cellar="$("$brew" --cellar)/$tool"
  if [[ -d $cellar ]]; then
    local d
    for d in "$cellar"/*.reinstall; do
      [[ -d $d ]] && rm -rf "$d"
    done
  fi

  if [[ $FLAG_FORCE == true ]]; then
    "$brew" reinstall "$tool" || true
  else
    "$brew" install "$tool" || true
  fi

  _brew_unlock

  if ! tool_healthy "$tool"; then
    echo "install failed" >&3
    exit 1
  fi

  echo "$(tool_version "$tool")" >&3
  exit 0
}

_step_brew_cosign() { _step_brew_tool cosign; }
_step_brew_mise() { _step_brew_tool mise; }
_step_brew_chezmoi() { _step_brew_tool chezmoi; }

_step_claude_code() {
  if [[ $FLAG_FORCE == false ]] && tool_healthy claude; then
    echo "$(tool_version claude)" >&3
    exit 2
  fi

  if [[ $FLAG_DRY_RUN == true ]]; then
    if tool_healthy claude; then
      echo "$(tool_version claude)" >&3
      exit 2
    fi
    echo "not installed" >&3
    exit 0
  fi

  if curl -fsSL https://claude.ai/install.sh | bash; then
    # Claude installer may update PATH in shell config; check common locations
    export PATH="$HOME/.claude/local/bin:$HOME/.local/bin:$PATH"
    if tool_healthy claude; then
      echo "$(tool_version claude)" >&3
      exit 0
    fi
    echo "installed (not in PATH)" >&3
    exit 4
  fi

  echo "installation failed" >&3
  exit 1
}

_step_cosign() {
  if [[ $FLAG_FORCE == false ]] && tool_healthy cosign; then
    echo "$(tool_version cosign)" >&3
    exit 2
  fi

  if [[ $FLAG_DRY_RUN == true ]]; then
    if tool_healthy cosign; then
      echo "$(tool_version cosign)" >&3
      exit 2
    fi
    echo "not installed" >&3
    exit 0
  fi

  # Try package managers first
  if [[ $FLAG_NO_PKG_MGR == false ]]; then
    if command -v pacman >/dev/null 2>&1; then
      if run_with_sudo pacman -S --noconfirm cosign && tool_healthy cosign; then
        echo "$(tool_version cosign)" >&3
        exit 0
      fi
    elif command -v apk >/dev/null 2>&1; then
      if run_with_sudo apk add cosign && tool_healthy cosign; then
        echo "$(tool_version cosign)" >&3
        exit 0
      fi
    elif command -v apt-get >/dev/null 2>&1; then
      if run_with_sudo apt-get update -y && run_with_sudo apt-get install -y cosign && tool_healthy cosign; then
        echo "$(tool_version cosign)" >&3
        exit 0
      fi
    elif command -v dnf >/dev/null 2>&1; then
      if run_with_sudo dnf install -y cosign && tool_healthy cosign; then
        echo "$(tool_version cosign)" >&3
        exit 0
      fi
    fi
  fi

  # Binary download fallback
  local system cosign_system cosign_url
  system=$(detect_system)
  cosign_system=${system/_/-}

  if [[ $COSIGN_VERSION == "latest" ]]; then
    cosign_url="$GITHUB_RELEASES_URL/$COSIGN_REPO/releases/latest/download/cosign-$cosign_system"
  else
    local ver=${COSIGN_VERSION#v}
    cosign_url="$GITHUB_RELEASES_URL/$COSIGN_REPO/releases/download/v$ver/cosign-$cosign_system"
  fi

  local tmp
  tmp=$(mktemp)
  local dl
  dl=$(get_download_cmd)
  if $dl "$cosign_url" >"$tmp"; then
    mv "$tmp" "$BIN_DIR/cosign"
    chmod +x "$BIN_DIR/cosign"
    echo "$(tool_version cosign)" >&3
    exit 0
  fi

  rm -f "$tmp"
  echo "download failed" >&3
  exit 1
}

_step_mise() {
  if [[ $FLAG_FORCE == false ]] && tool_healthy mise; then
    echo "$(tool_version mise)" >&3
    exit 2
  fi

  if [[ $FLAG_DRY_RUN == true ]]; then
    if tool_healthy mise; then
      echo "$(tool_version mise)" >&3
      exit 2
    fi
    echo "not installed" >&3
    exit 0
  fi

  # Try package managers first
  if [[ $FLAG_NO_PKG_MGR == false ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      local system repo_arch=""
      system=$(detect_system)
      case $system in
      linux_amd64) repo_arch="amd64" ;;
      linux_arm64) repo_arch="arm64" ;;
      esac
      if [[ -n $repo_arch ]]; then
        if run_with_sudo apt-get update -y &&
          run_with_sudo apt-get install -y gpg wget curl 2>/dev/null &&
          run_with_sudo install -dm 755 /etc/apt/keyrings; then
          local dl
          dl=$(get_download_cmd)
          if $dl https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | run_with_sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null; then
            echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$repo_arch] https://mise.jdx.dev/deb stable main" |
              run_with_sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
            if run_with_sudo apt-get update && run_with_sudo apt-get install -y mise && tool_healthy mise; then
              echo "$(tool_version mise)" >&3
              exit 0
            fi
          fi
        fi
      fi
    elif command -v pacman >/dev/null 2>&1; then
      if run_with_sudo pacman -S --noconfirm mise && tool_healthy mise; then
        echo "$(tool_version mise)" >&3
        exit 0
      fi
    elif command -v apk >/dev/null 2>&1; then
      if run_with_sudo apk add mise && tool_healthy mise; then
        echo "$(tool_version mise)" >&3
        exit 0
      fi
    elif command -v dnf >/dev/null 2>&1; then
      if command -v dnf5 >/dev/null 2>&1; then
        run_with_sudo dnf5 copr enable -y jdx/mise 2>/dev/null || true
      else
        run_with_sudo dnf copr enable -y jdx/mise 2>/dev/null || true
      fi
      if run_with_sudo dnf install -y mise && tool_healthy mise; then
        echo "$(tool_version mise)" >&3
        exit 0
      fi
    fi
  fi

  # Official installer fallback
  if curl -fsSL https://mise.run | sh; then
    export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/bin:$PATH"
    if tool_healthy mise; then
      echo "$(tool_version mise)" >&3
      exit 0
    fi
  fi

  echo "installation failed" >&3
  exit 1
}

_step_chezmoi() {
  if [[ $FLAG_FORCE == false ]] && tool_healthy chezmoi; then
    echo "$(tool_version chezmoi)" >&3
    exit 2
  fi

  if [[ $FLAG_DRY_RUN == true ]]; then
    if tool_healthy chezmoi; then
      echo "$(tool_version chezmoi)" >&3
      exit 2
    fi
    echo "not installed" >&3
    exit 0
  fi

  # Try package managers first
  if [[ $FLAG_NO_PKG_MGR == false ]]; then
    if command -v pacman >/dev/null 2>&1; then
      if run_with_sudo pacman -S --noconfirm chezmoi && tool_healthy chezmoi; then
        echo "$(tool_version chezmoi)" >&3
        exit 0
      fi
    elif command -v apk >/dev/null 2>&1; then
      if run_with_sudo apk add chezmoi && tool_healthy chezmoi; then
        echo "$(tool_version chezmoi)" >&3
        exit 0
      fi
    elif command -v apt-get >/dev/null 2>&1; then
      if run_with_sudo apt-get update -y && run_with_sudo apt-get install -y chezmoi && tool_healthy chezmoi; then
        echo "$(tool_version chezmoi)" >&3
        exit 0
      fi
    elif command -v dnf >/dev/null 2>&1; then
      if run_with_sudo dnf install -y chezmoi && tool_healthy chezmoi; then
        echo "$(tool_version chezmoi)" >&3
        exit 0
      fi
    fi
  fi

  # Binary download with optional cosign verification
  local dl system version
  dl=$(get_download_cmd)
  system=$(detect_system)

  if [[ $CHEZMOI_VERSION == "latest" ]]; then
    version=$($dl "$GITHUB_API_URL/repos/$CHEZMOI_REPO/releases/latest" | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
  else
    version=${CHEZMOI_VERSION#v}
  fi

  local base_url="$GITHUB_RELEASES_URL/$CHEZMOI_REPO/releases/download/v$version"
  local archive="chezmoi_${version}_${system}.tar.gz"
  local checksums="chezmoi_${version}_checksums.txt"

  local tmp
  tmp=$(mktemp -d)

  $dl "$base_url/$archive" >"$tmp/$archive"
  $dl "$base_url/$checksums" >"$tmp/$checksums"

  # Signature verification with cosign (if enabled and cosign available)
  if [[ $FLAG_NO_VERIFY == false ]] && command -v cosign >/dev/null 2>&1; then
    local signature="chezmoi_${version}_checksums.txt.sig"
    local pubkey="chezmoi_cosign.pub"
    $dl "$base_url/$signature" >"$tmp/$signature"
    $dl "$base_url/$pubkey" >"$tmp/$pubkey"
    cosign verify-blob "$tmp/$checksums" --signature "$tmp/$signature" --key "$tmp/$pubkey"
  fi

  # Verify checksum
  (cd "$tmp" && verify_checksum "$archive" "$checksums")

  # Extract and install
  (cd "$tmp" && tar -xzf "$archive" chezmoi)
  mv "$tmp/chezmoi" "$BIN_DIR/chezmoi"
  chmod +x "$BIN_DIR/chezmoi"
  rm -rf "$tmp"

  echo "$(tool_version chezmoi)" >&3
  exit 0
}

_step_apply() {
  if [[ $FLAG_DRY_RUN == true ]]; then
    echo "would apply dotfiles" >&3
    exit 0
  fi

  # Find chezmoi — may be in BIN_DIR, brew path, or system PATH
  local chezmoi=""
  chezmoi=$(command -v chezmoi 2>/dev/null) || true
  if [[ -z $chezmoi ]]; then
    local p
    for p in "$BIN_DIR/chezmoi" /opt/homebrew/bin/chezmoi /usr/local/bin/chezmoi; do
      if [[ -x $p ]]; then
        chezmoi=$p
        break
      fi
    done
  fi
  [[ -z $chezmoi ]] && {
    echo "chezmoi not found" >&3
    exit 1
  }

  # Reset persistent state so run_once/run_onchange scripts re-run
  # (nuke already wiped config dir; this handles --force without --nuke)
  if [[ $FLAG_FORCE == true ]]; then
    "$chezmoi" state reset --force 2>/dev/null || true
  fi

  local args=(init --apply --source="$SCRIPT_DIR" --working-tree="$SCRIPT_DIR")

  [[ $FLAG_FORCE == true ]] && args+=(--force)

  [[ -n $GIT_USER_NAME ]] && args+=(--promptString "Git user.name=$GIT_USER_NAME")
  [[ -n $GIT_USER_EMAIL ]] && args+=(--promptString "Git user.email=$GIT_USER_EMAIL")
  [[ -n $FLAG_BEDROCK ]] && args+=(--promptBool "Use AWS Bedrock for Claude Code=$FLAG_BEDROCK")

  if ((${#CHEZMOI_PASSTHROUGH[@]} > 0)); then
    args+=("${CHEZMOI_PASSTHROUGH[@]}")
  fi

  "$chezmoi" "${args[@]}"

  echo "dotfiles applied" >&3
  exit 0
}

# ═══════════════════════════════════════════════════════════════════════
# Platform-specific step registration
# ═══════════════════════════════════════════════════════════════════════

register_steps() {
  local os
  os=$(uname -s)

  step preflight "Pre-flight checks" _step_preflight

  if [[ $os == Darwin ]] && [[ $FLAG_NO_PKG_MGR == false ]]; then
    # macOS with Homebrew: individual brew installs after Homebrew is ready
    step homebrew "Homebrew" _step_homebrew after preflight
    step cosign "Cosign" _step_brew_cosign after homebrew
    step mise "Mise" _step_brew_mise after homebrew
    step chezmoi "Chezmoi" _step_brew_chezmoi after homebrew
    step claude-code "Claude Code" _step_claude_code after preflight
    step apply "Apply dotfiles" _step_apply after cosign mise chezmoi claude-code
  else
    # Linux / macOS without package manager: parallel binary downloads
    step cosign "Cosign" _step_cosign after preflight
    step mise "Mise" _step_mise after preflight
    step claude-code "Claude Code" _step_claude_code after preflight
    if [[ $FLAG_NO_VERIFY == false ]]; then
      step chezmoi "Chezmoi" _step_chezmoi after cosign
    else
      step chezmoi "Chezmoi" _step_chezmoi after preflight
    fi
    step apply "Apply dotfiles" _step_apply after mise chezmoi claude-code
  fi
}

# ═══════════════════════════════════════════════════════════════════════
# Main + cleanup
# ═══════════════════════════════════════════════════════════════════════

_INTERRUPTED=false

_cleanup() {
  local rc=$?
  # Kill running step processes
  if ((${#STEP_PIDS[@]} > 0)); then
    local i
    for i in "${!STEP_PIDS[@]}"; do
      if [[ -n ${STEP_PIDS[$i]} ]]; then
        kill "${STEP_PIDS[$i]}" 2>/dev/null || true
        wait "${STEP_PIDS[$i]}" 2>/dev/null || true
        STEP_PIDS[$i]=""
      fi
    done
  fi

  # On interrupt, mark running steps as failed and pending as blocked
  if [[ $_INTERRUPTED == true ]] && ((${#STEP_STATES[@]} > 0)); then
    local i
    for i in "${!STEP_STATES[@]}"; do
      case ${STEP_STATES[$i]} in
      running)
        STEP_STATES[$i]="failed"
        STEP_ELAPSED[$i]=$((SECONDS - STEP_START_SEC[i]))
        STEP_MESSAGES[$i]="interrupted"
        ;;
      pending) STEP_STATES[$i]="blocked" ;;
      esac
    done
    # Show report — skip render_update to avoid garbled output from
    # background processes that may have written to the terminal
    if [[ $FLAG_QUIET == false ]]; then
      if [[ ${IS_TTY:-} == true ]]; then
        tput cnorm 2>/dev/null || true
        printf '\n\n'
      fi
      _report
    fi
    # Write summary to log directory
    if [[ -n ${LOG_DIR:-} ]]; then
      write_summary
    fi
  fi

  # Restore cursor (only when TTY)
  [[ ${IS_TTY:-} == true ]] && { tput cnorm 2>/dev/null || true; }
  # Clean up temp message files and brew lock
  rmdir "${_BREW_LOCK:-/nonexistent}" 2>/dev/null || true
  if ((${#STEP_MSG_FILES[@]} > 0)); then
    local f
    for f in "${STEP_MSG_FILES[@]}"; do
      [[ -n $f ]] && rm -f "$f"
    done
  fi
  # On abnormal exit with logging, point to logs
  if ((rc != 0)) && ((rc != 130)) && [[ -n ${LOG_DIR:-} ]] && [[ $FLAG_QUIET == false ]]; then
    printf '\n\033[31m[ERROR]\033[0m Full log: %s\n' "$LOG_DIR" >&2
  fi
}

main() {
  # Capture original command for retry suggestions
  if [[ -z $_ORIGINAL_CMD ]]; then
    _ORIGINAL_CMD="$0 $*"
    export _ORIGINAL_CMD
  fi

  parse_flags "$@"

  # --nuke without --force requires interactive confirmation
  if [[ $FLAG_NUKE == true ]] && [[ $FLAG_EXPLICIT_FORCE != true ]] && [[ $FLAG_QUIET == true ]]; then
    printf 'error: --nuke requires --force in quiet mode\n' >&2
    exit 1
  fi

  [[ $FLAG_DEBUG == true ]] && set -x

  # Quiet mode suppresses visible output
  [[ $FLAG_QUIET == true ]] && IS_TTY=false

  _setup_colors
  resolve_versions
  add_to_path

  # Init logging and re-exec under script(1) for combined log capture
  if [[ $FLAG_DRY_RUN == false ]] && [[ -z ${_DOTFILES_LOG_GUARD:-} ]]; then
    init_logging
    export _DOTFILES_LOG_GUARD=1 LOG_DIR
    case $(uname -s) in
    Darwin) exec script -q "$LOG_DIR/install.log" "$0" "$@" ;;
    *) exec script -q -c "$(printf '%q ' "$0" "$@")" "$LOG_DIR/install.log" ;;
    esac
    # exec failed — continue without combined log
    unset _DOTFILES_LOG_GUARD
  fi

  trap _cleanup EXIT
  trap '_INTERRUPTED=true; exit 130' INT TERM

  # Greeting (collect identity values + sudo prompt on macOS)
  _greeting

  # Ensure sudo is acquired even if greeting was skipped (quiet/all flags)
  _acquire_sudo_if_needed

  # Nuke: tear everything down before rebuilding
  if [[ $FLAG_NUKE == true ]] && [[ $FLAG_DRY_RUN == false ]]; then
    _nuke_teardown
  fi

  # Print header
  if [[ $FLAG_QUIET == false ]]; then
    if [[ $FLAG_DRY_RUN == true ]]; then
      _print_header "dotfiles install --dry-run" "$YELLOW"
    else
      _print_header "dotfiles install"
    fi
  fi

  # Register and run steps
  register_steps

  if [[ $FLAG_DRY_RUN == true ]]; then
    run_dry
  else
    run
  fi

  # Write summary to log directory
  if [[ -n ${LOG_DIR:-} ]]; then
    write_summary
  fi

  # Quiet mode: emit errors to stderr
  if [[ $FLAG_QUIET == true ]]; then
    local i
    for i in "${!STEP_STATES[@]}"; do
      if [[ ${STEP_STATES[$i]} == "failed" ]]; then
        printf 'FAIL: %s (%s)\n' "${STEP_LABELS[$i]}" "${STEP_MESSAGES[$i]}" >&2
        if [[ -n ${LOG_DIR:-} ]]; then
          printf '  log: %s/%s.log\n' "$LOG_DIR" "${STEP_IDS[$i]}" >&2
        fi
      fi
    done
  fi

  # Exit with failure if any step failed
  local s
  for s in "${STEP_STATES[@]}"; do
    [[ $s == "failed" ]] && exit 1
  done
  exit 0
}

main "$@"
