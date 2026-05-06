#!/usr/bin/env bash
# =============================================================================
#  OpenCode + OhMyOpenCode Bootstrapper — macOS
#  Designed & built by JustifiedWin
#  Contact: justin@ozarkstacks.com
# =============================================================================
#
#  USAGE:
#    bash deploy-opencode-mac.sh            # Full install
#    bash deploy-opencode-mac.sh --dry-run  # Preview only, no changes made
#
# =============================================================================

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# ==============================================================================
# Terminal colors
# ==============================================================================

RESET="\033[0m"
GREEN="\033[0;32m"
DKGREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
WHITE="\033[1;37m"
GRAY="\033[0;90m"
MAGENTA="\033[0;35m"
RED="\033[0;31m"

# ==============================================================================
# Helpers
# ==============================================================================

print_header() {
  echo ""
  echo -e "${CYAN}==================================================${RESET}"
  echo -e "${CYAN}  $1${RESET}"
  echo -e "${CYAN}==================================================${RESET}"
}

print_step()  { echo -e "  ${WHITE}> $1${RESET}"; }
print_ok()    { echo -e "  ${GREEN}[OK] $1${RESET}"; }
print_warn()  { echo -e "  ${YELLOW}[!!] $1${RESET}"; }
print_fail()  { echo -e "  ${RED}[XX] $1${RESET}"; }

command_exists() { command -v "$1" &>/dev/null; }

prompt_secret() {
  local label="$1"
  local hint="${2:-}"
  [[ -n "$hint" ]] && echo -e "    ${GRAY}$hint${RESET}" >&2
  local val
  read -s -r -p "    Enter $label: " val
  echo "" >&2
  echo "$val"
}

# ==============================================================================
# Splash screen
# ==============================================================================

type_line() {
  local text="$1"
  local color="${2:-$WHITE}"
  local delay="${3:-0.03}"
  for ((i=0; i<${#text}; i++)); do
    printf "%b%s%b" "$color" "${text:$i:1}" "$RESET"
    sleep "$delay"
  done
  echo ""
}

loading_bar() {
  local label="$1"
  local duration="${2:-1}"
  local width=36
  local sleep_per
  sleep_per=$(echo "scale=4; $duration / $width" | bc)
  printf "  %s [" "$label"
  for ((i=0; i<width; i++)); do
    printf "%b#%b" "$GREEN" "$RESET"
    sleep "$sleep_per"
  done
  echo "]"
}

blink_cursor() {
  local times="${1:-4}"
  for ((i=0; i<times; i++)); do
    printf "%b#%b" "$GREEN" "$RESET"
    sleep 0.12
    printf "\b "
    sleep 0.12
  done
  echo ""
}

matrix_drip() {
  local pool="01アイウエオカキクケコサシスセソタチツテトナニヌネノ"
  local line=""
  for ((i=0; i<68; i++)); do
    local len=${#pool}
    local idx=$(( RANDOM % len ))
    line+="${pool:$idx:1}"
  done
  echo -e "  ${DKGREEN}${line}${RESET}"
}

show_splash() {
  clear
  echo ""
  sleep 0.1

  # Main logo
  echo -e "${DKGREEN}  +------------------------------------------------------------------+${RESET}"
  echo -e "${DKGREEN}  |                                                                  |${RESET}"
  echo -e "${DKGREEN}  |${GREEN}   ██████╗ ██████╗ ███████╗███╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗ ${DKGREEN}|${RESET}"
  echo -e "${DKGREEN}  |${GREEN}  ██╔══██╗██╔══██╗██╔════╝████╗ ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝ ${DKGREEN}|${RESET}"
  echo -e "${DKGREEN}  |${GREEN}  ██║  ██║██████╔╝█████╗  ██╔██╗██║██║     ██║   ██║██║  ██║█████╗   ${DKGREEN}|${RESET}"
  echo -e "${DKGREEN}  |${GREEN}  ██║  ██║██╔═══╝ ██╔══╝  ██║╚████║██║     ██║   ██║██║  ██║██╔══╝   ${DKGREEN}|${RESET}"
  echo -e "${DKGREEN}  |${GREEN}  ██████╔╝██║     ███████╗██║  ███║╚██████╗╚██████╔╝██████╔╝███████╗ ${DKGREEN}|${RESET}"
  echo -e "${DKGREEN}  |${GREEN}  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚══╝ ╚═════╝ ╚═════╝ ╚═════╝╚══════╝ ${DKGREEN}|${RESET}"
  echo -e "${DKGREEN}  |                                                                  |${RESET}"
  echo -e "${DKGREEN}  +------------------------------------------------------------------+${RESET}"
  echo ""

  # Tagline typewriter
  printf "  "
  type_line "[ OpenCode + OhMyOpenCode Bootstrapper ]" "$CYAN" "0.025"
  echo ""

  # DryRun badge
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${YELLOW}+----------------------------------+${RESET}"
    echo -e "  ${YELLOW}|  !! DRY-RUN MODE - NO CHANGES   |${RESET}"
    echo -e "  ${YELLOW}|  Nothing will be installed or    |${RESET}"
    echo -e "  ${YELLOW}|  written to your system.         |${RESET}"
    echo -e "  ${YELLOW}+----------------------------------+${RESET}"
    echo ""
  fi

  sleep 0.2

  # Author card
  echo -e "  ${GRAY}+-----------------------------------------------------------------+${RESET}"
  echo -e "  ${GRAY}|  Designed & built by  ${CYAN}JustifiedWin${GRAY}                              |${RESET}"
  echo -e "  ${GRAY}|  Contact:             ${GREEN}justin@ozarkstacks.com${GRAY}                    |${RESET}"
  echo -e "  ${GRAY}|  Powered by:          ${WHITE}OpenCode (SST)${GRAY}  +  ${MAGENTA}OhMyOpenCode${GRAY}               |${RESET}"
  echo -e "  ${GRAY}+-----------------------------------------------------------------+${RESET}"
  echo ""
  sleep 0.3

  # Matrix drip
  matrix_drip
  sleep 0.08
  matrix_drip
  sleep 0.08
  echo ""

  # Loading bars
  loading_bar "Initializing runtime........" 0.7
  loading_bar "Loading agent manifest......" 0.6
  loading_bar "Booting deployment engine..." 0.8
  echo ""

  # Blink then ready
  printf "  "
  blink_cursor 4
  printf "  "
  type_line "SYSTEM READY. Starting deployment..." "$GREEN" "0.03"
  echo ""
  sleep 0.5
}

show_splash

# ==============================================================================
# Step 1: Prerequisites
# ==============================================================================

print_header "STEP 1 -- Prerequisites"

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would check for: Homebrew, Node.js, Git, npm"
  print_step "[DRY-RUN] Would install any missing tools via Homebrew"
  print_ok   "[DRY-RUN] Prerequisites check skipped"
else
  # Homebrew
  if ! command_exists brew; then
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    print_ok "Homebrew found ($(brew --version | head -1))"
  fi

  # Node.js
  if ! command_exists node; then
    print_step "Installing Node.js LTS via Homebrew..."
    brew install node@lts
    brew link node@lts --force --overwrite
  else
    print_ok "Node.js found ($(node --version))"
  fi

  # Git (usually pre-installed on Mac via Xcode CLT)
  if ! command_exists git; then
    print_step "Installing Git via Homebrew..."
    brew install git
  else
    print_ok "Git found ($(git --version))"
  fi

  # npm
  if ! command_exists npm; then
    print_fail "npm not found even after Node install. Please restart your terminal and re-run."
    exit 1
  fi
  print_ok "npm found ($(npm --version))"
fi

# ==============================================================================
# Step 2: Install OpenCode CLI
# ==============================================================================

print_header "STEP 2 -- OpenCode CLI"

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would run: npm install -g opencode-ai@latest"
  print_ok   "[DRY-RUN] OpenCode CLI install skipped"
else
  if command_exists opencode; then
    print_ok "OpenCode already installed (v$(opencode --version 2>/dev/null))"
    print_step "Upgrading to latest..."
    npm install -g opencode-ai@latest --silent
  else
    print_step "Installing OpenCode CLI globally..."
    npm install -g opencode-ai@latest
  fi

  if ! command_exists opencode; then
    print_fail "OpenCode install failed. Check npm output above."
    exit 1
  fi
  print_ok "OpenCode installed (v$(opencode --version))"
fi

# ==============================================================================
# Step 3: Config directory
# ==============================================================================

print_header "STEP 3 -- Config Directory"

CONFIG_DIR="$HOME/.config/opencode"

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would create (if missing): $CONFIG_DIR"
  print_ok   "[DRY-RUN] Config directory step skipped"
else
  mkdir -p "$CONFIG_DIR"
  print_ok "Config dir ready: $CONFIG_DIR"
fi

# ==============================================================================
# Step 4: Install oh-my-openagent plugin
# ==============================================================================

print_header "STEP 4 -- OhMyOpenCode Plugin"

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would run: npm install oh-my-openagent@latest (in $CONFIG_DIR)"
  print_ok   "[DRY-RUN] Plugin install skipped"
else
  print_step "Installing oh-my-openagent@latest into config dir..."
  pushd "$CONFIG_DIR" > /dev/null
  npm install oh-my-openagent@latest --save 2>&1 | tail -3
  popd > /dev/null

  if [[ -d "$CONFIG_DIR/node_modules/oh-my-openagent" ]]; then
    print_ok "oh-my-openagent installed."
  else
    print_fail "oh-my-openagent install failed."
    exit 1
  fi
fi

# ==============================================================================
# Step 5: Write opencode.json
# ==============================================================================

print_header "STEP 5 -- opencode.json"

print_step "Prompting for GitHub Personal Access Token..."
echo -e "    ${GRAY}(github.com > Settings > Developer settings > Personal access tokens)${RESET}"
echo -e "    ${GRAY}Recommended scopes: repo, read:org, read:user${RESET}"

if [[ "$DRY_RUN" == true ]]; then
  GITHUB_PAT="ghp_DRYRUN_PLACEHOLDER"
  print_ok "[DRY-RUN] GitHub PAT prompt skipped -- using placeholder"
else
  GITHUB_PAT=$(prompt_secret "GitHub PAT")
fi

OPENCODE_JSON_PATH="$CONFIG_DIR/opencode.json"
OPENCODE_JSON_CONTENT=$(cat <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "plugin": ["oh-my-openagent@latest"],
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp@latest"],
      "enabled": true
    },
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "enabled": true,
      "environment": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_PAT"
      }
    },
    "memory": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
      "enabled": true
    },
    "fetch": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-fetch"],
      "enabled": true
    },
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "WORKSPACE_PATH_PLACEHOLDER"],
      "enabled": true
    }
  }
}
EOF
)

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would write opencode.json to: $OPENCODE_JSON_PATH"
  echo -e "${GRAY}$OPENCODE_JSON_CONTENT${RESET}"
  print_ok "[DRY-RUN] File write skipped"
else
  echo "$OPENCODE_JSON_CONTENT" > "$OPENCODE_JSON_PATH"
  print_ok "Written: $OPENCODE_JSON_PATH"
fi

# ==============================================================================
# Step 6: Write oh-my-openagent.json
# ==============================================================================

print_header "STEP 6 -- oh-my-openagent.json"

OMO_JSON_PATH="$CONFIG_DIR/oh-my-openagent.json"
OMO_JSON_CONTENT=$(cat <<'EOF'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus":          { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3.1-pro-preview" }] },
    "oracle":            { "model": "anthropic/claude-opus-4-6",    "fallback_models": [{ "model": "google/gemini-3.1-pro-preview", "variant": "high" }] },
    "explore":           { "model": "anthropic/claude-haiku-4-5" },
    "multimodal-looker": { "model": "opencode/gpt-5-nano" },
    "prometheus":        { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "metis":             { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "momus":             { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "atlas":             { "model": "anthropic/claude-sonnet-4-6" },
    "sisyphus-junior":   { "model": "anthropic/claude-haiku-4-5",   "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] }
  },
  "categories": {
    "visual-engineering": { "model": "google/gemini-3.1-pro-preview",  "fallback_models": [{ "model": "anthropic/claude-sonnet-4-6" }] },
    "ultrabrain":         { "model": "anthropic/claude-opus-4-6",      "fallback_models": [{ "model": "google/gemini-3.1-pro-preview", "variant": "high" }] },
    "deep":               { "model": "anthropic/claude-opus-4-6",      "fallback_models": [{ "model": "google/gemini-3.1-pro-preview", "variant": "high" }] },
    "artistry":           { "model": "google/gemini-3.1-pro-preview",  "fallback_models": [{ "model": "anthropic/claude-sonnet-4-6" }] },
    "quick":              { "model": "anthropic/claude-haiku-4-5",     "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "unspecified-low":    { "model": "anthropic/claude-haiku-4-5",     "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "unspecified-high":   { "model": "anthropic/claude-sonnet-4-6",    "fallback_models": [{ "model": "google/gemini-3.1-pro-preview" }] },
    "writing":            { "model": "google/gemini-3-flash-preview",  "fallback_models": [{ "model": "anthropic/claude-haiku-4-5" }] }
  }
}
EOF
)

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would write oh-my-openagent.json to: $OMO_JSON_PATH"
  print_ok   "[DRY-RUN] File write skipped"
else
  echo "$OMO_JSON_CONTENT" > "$OMO_JSON_PATH"
  print_ok "Written: $OMO_JSON_PATH"
fi

# ==============================================================================
# Step 7: API Keys
# ==============================================================================

print_header "STEP 7 -- API Keys"

echo ""
echo -e "  ${WHITE}You need keys for Anthropic, Google, and OpenAI.${RESET}"
echo -e "  ${GRAY}Press Enter to skip any provider (you can add it later via the opencode UI).${RESET}"
echo ""

AUTH_JSON_PATH="$HOME/.local/share/opencode/auth.json"

if [[ "$DRY_RUN" == true ]]; then
  print_step "[DRY-RUN] Would prompt for: Anthropic, Google, and OpenAI API keys"
  print_step "[DRY-RUN] Would write auth.json to: $AUTH_JSON_PATH"
  print_ok   "[DRY-RUN] API key prompts and auth.json write skipped"
else
  echo -e "  ${WHITE}[Anthropic]  console.anthropic.com > API Keys${RESET}"
  ANTHROPIC_KEY=$(prompt_secret "Anthropic API key (sk-ant-...)" "(leave blank to skip)")

  echo ""
  echo -e "  ${WHITE}[Google]     aistudio.google.com > Get API Key${RESET}"
  GOOGLE_KEY=$(prompt_secret "Google API key (AIza...)" "(leave blank to skip)")

  echo ""
  echo -e "  ${WHITE}[OpenAI]     platform.openai.com > API Keys  (optional -- or log in via opencode UI)${RESET}"
  OPENAI_KEY=$(prompt_secret "OpenAI API key (sk-...)" "(leave blank to skip)")

  if [[ -n "$ANTHROPIC_KEY" || -n "$GOOGLE_KEY" || -n "$OPENAI_KEY" ]]; then
    mkdir -p "$(dirname "$AUTH_JSON_PATH")"
    ANTHROPIC_KEY="$ANTHROPIC_KEY" GOOGLE_KEY="$GOOGLE_KEY" OPENAI_KEY="$OPENAI_KEY" \
      python3 -c '
import json, os
data = {}
for provider in ("anthropic", "google", "openai"):
    key = os.environ.get(provider.upper() + "_KEY", "")
    if key:
        data[provider] = {"type": "api", "key": key}
print(json.dumps(data, indent=2))
' > "$AUTH_JSON_PATH"
    print_ok "auth.json written to $AUTH_JSON_PATH"
  else
    print_warn "No API keys entered. Run opencode and use the built-in auth flow to add providers."
  fi
fi

# ==============================================================================
# Step 8: Workspace Directory
# ==============================================================================

print_header "STEP 8 -- Workspace Directory"

echo ""
echo -e "  ${WHITE}The filesystem MCP server is scoped to a single directory.${RESET}"
echo -e "  ${GRAY}Default: $HOME/Documents${RESET}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  WORKSPACE_PATH="$HOME/Documents"
  print_step "[DRY-RUN] Would prompt for workspace directory"
  print_step "[DRY-RUN] Would default to: $WORKSPACE_PATH"
  print_step "[DRY-RUN] Would patch filesystem MCP path in opencode.json"
  print_ok   "[DRY-RUN] Workspace step skipped"
else
  read -r -p "  Enter workspace path (or press Enter for default): " CUSTOM_WORKSPACE
  if [[ -n "$CUSTOM_WORKSPACE" ]]; then
    WORKSPACE_PATH="$CUSTOM_WORKSPACE"
  else
    WORKSPACE_PATH="$HOME/Documents"
  fi

  mkdir -p "$WORKSPACE_PATH"
  print_ok "Workspace: $WORKSPACE_PATH"

  # Patch placeholder in opencode.json
  # Use a temp file for compatibility with both GNU and BSD sed (macOS)
  sed -i.bak "s|WORKSPACE_PATH_PLACEHOLDER|$WORKSPACE_PATH|g" "$OPENCODE_JSON_PATH"
  rm -f "${OPENCODE_JSON_PATH}.bak"
  print_ok "opencode.json updated with workspace path."
fi

# ==============================================================================
# Done
# ==============================================================================

print_header "DONE"

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo -e "  ${YELLOW}DRY-RUN COMPLETE -- Nothing was installed or written.${RESET}"
  echo ""
  echo -e "  ${WHITE}What WOULD have happened:${RESET}"
  echo -e "  ${GRAY}  1. Checked/installed: Homebrew, Node.js, Git, npm${RESET}"
  echo -e "  ${GRAY}  2. Installed: opencode-ai@latest (global npm)${RESET}"
  echo -e "  ${GRAY}  3. Created:   $HOME/.config/opencode/${RESET}"
  echo -e "  ${GRAY}  4. Installed: oh-my-openagent@latest (plugin)${RESET}"
  echo -e "  ${GRAY}  5. Written:   opencode.json  (with GitHub PAT + MCP config)${RESET}"
  echo -e "  ${GRAY}  6. Written:   oh-my-openagent.json  (agent + category models)${RESET}"
  echo -e "  ${GRAY}  7. Written:   auth.json  (Anthropic / Google / OpenAI keys)${RESET}"
  echo -e "  ${GRAY}  8. Set workspace dir and patched filesystem MCP path${RESET}"
  echo ""
  echo -e "  ${WHITE}To run for real, omit the --dry-run flag:${RESET}"
  echo -e "  ${CYAN}    bash deploy-opencode-mac.sh${RESET}"
else
  echo -e "  ${GREEN}Everything is installed and configured.${RESET}"
  echo ""
  echo -e "  ${WHITE}Quick start:${RESET}"
  echo -e "  ${GRAY}    cd \"$WORKSPACE_PATH\"${RESET}"
  echo -e "  ${GRAY}    opencode${RESET}"
  echo ""
  echo -e "  ${WHITE}Config files:${RESET}"
  echo -e "  ${GRAY}    $OPENCODE_JSON_PATH${RESET}"
  echo -e "  ${GRAY}    $OMO_JSON_PATH${RESET}"
  echo -e "  ${GRAY}    $AUTH_JSON_PATH${RESET}"
  echo ""
  echo -e "  ${GRAY}If providers are missing, run opencode and use the built-in login flow.${RESET}"
fi
echo ""
