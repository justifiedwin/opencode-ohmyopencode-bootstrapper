#Requires -Version 5.1
<#
.SYNOPSIS
    Deploys OpenCode + OhMyOpenCode to a fresh Windows machine.

.DESCRIPTION
    - Installs prerequisites: winget, Node.js, Git (if missing)
    - Installs OpenCode CLI globally via npm
    - Writes opencode.json config with MCP servers
    - Writes oh-my-openagent.json with agent/category model config
    - Installs oh-my-openagent npm dependency
    - Prompts for all API keys interactively (nothing hardcoded)

.PARAMETER DryRun
    Run the full script without installing or writing anything.
    Splash screen, prompts, and all steps execute -- but no system changes are made.
    Use this to preview the experience before deploying for real.

.EXAMPLE
    .\deploy-opencode.ps1 -DryRun

.NOTES
    Run as your normal user account (NOT as Administrator).
    winget will be used for Node/Git if they are missing.
#>

param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure scripts are allowed to run on this machine
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq 'Restricted' -or $policy -eq 'Undefined') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# Force UTF-8 so Katakana and Unicode box-drawing render correctly
$prevCodePage = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# --------------------------------------------------
# Helpers
# --------------------------------------------------

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "  > $Text" -ForegroundColor White
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  [!!] $Text" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Text)
    Write-Host "  [XX] $Text" -ForegroundColor Red
}

function Prompt-Secret {
    param([string]$Label, [string]$Hint = "")
    if ($Hint) { Write-Host "    $Hint" -ForegroundColor DarkGray }
    $secure = Read-Host "    Enter $Label" -AsSecureString
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
    return $plain
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WithWinget {
    param([string]$PackageId, [string]$Name)
    Write-Step "Installing $Name via winget..."
    winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$Name installation failed. Please install manually and re-run."
        exit 1
    }
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Ok "$Name installed."
}

# --------------------------------------------------
# Splash screen
# --------------------------------------------------

function Show-Splash {

    function Type-Line {
        param([string]$Text, [ConsoleColor]$Color = 'White', [int]$DelayMs = 18)
        foreach ($char in $Text.ToCharArray()) {
            Write-Host $char -NoNewline -ForegroundColor $Color
            Start-Sleep -Milliseconds $DelayMs
        }
        Write-Host ""
    }

    function Blink-Cursor {
        param([int]$Times = 3)
        for ($i = 0; $i -lt $Times; $i++) {
            Write-Host "#" -NoNewline -ForegroundColor Green
            Start-Sleep -Milliseconds 120
            Write-Host "`b " -NoNewline
            Start-Sleep -Milliseconds 120
        }
        Write-Host ""
    }

    function Show-LoadingBar {
        param([string]$Label, [int]$DurationMs = 900)
        $width = 36
        Write-Host "  $Label [" -NoNewline -ForegroundColor DarkGray
        $steps = $width
        $sleepMs = [math]::Max(1, [int]($DurationMs / $steps))
        for ($i = 0; $i -lt $steps; $i++) {
            Write-Host "#" -NoNewline -ForegroundColor Green
            Start-Sleep -Milliseconds $sleepMs
        }
        Write-Host "]" -ForegroundColor DarkGray
    }

    Clear-Host
    Write-Host ""
    Start-Sleep -Milliseconds 120

    # Main logo
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor DarkGreen
    Write-Host "  |                                                                  |" -ForegroundColor DarkGreen
    Write-Host "  |" -NoNewline -ForegroundColor DarkGreen
    Write-Host "   ██████╗ ██████╗ ███████╗███╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗ " -NoNewline -ForegroundColor Green
    Write-Host "|" -ForegroundColor DarkGreen
    Write-Host "  |" -NoNewline -ForegroundColor DarkGreen
    Write-Host "  ██╔══██╗██╔══██╗██╔════╝████╗ ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝ " -NoNewline -ForegroundColor Green
    Write-Host "|" -ForegroundColor DarkGreen
    Write-Host "  |" -NoNewline -ForegroundColor DarkGreen
    Write-Host "  ██║  ██║██████╔╝█████╗  ██╔██╗██║██║     ██║   ██║██║  ██║█████╗   " -NoNewline -ForegroundColor Green
    Write-Host "|" -ForegroundColor DarkGreen
    Write-Host "  |" -NoNewline -ForegroundColor DarkGreen
    Write-Host "  ██║  ██║██╔═══╝ ██╔══╝  ██║╚████║██║     ██║   ██║██║  ██║██╔══╝   " -NoNewline -ForegroundColor Green
    Write-Host "|" -ForegroundColor DarkGreen
    Write-Host "  |" -NoNewline -ForegroundColor DarkGreen
    Write-Host "  ██████╔╝██║     ███████╗██║  ███║╚██████╗╚██████╔╝██████╔╝███████╗ " -NoNewline -ForegroundColor Green
    Write-Host "|" -ForegroundColor DarkGreen
    Write-Host "  |" -NoNewline -ForegroundColor DarkGreen
    Write-Host "  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚══╝ ╚═════╝ ╚═════╝ ╚═════╝╚══════╝ " -NoNewline -ForegroundColor Green
    Write-Host "|" -ForegroundColor DarkGreen
    Write-Host "  |                                                                  |" -ForegroundColor DarkGreen
    Write-Host "  +------------------------------------------------------------------+" -ForegroundColor DarkGreen
    Write-Host ""

    # Tagline typewriter
    Write-Host "  " -NoNewline
    Type-Line "[ OpenCode + OhMyOpenCode Bootstrapper ]" -Color Cyan -DelayMs 22
    Write-Host ""

    # DryRun badge
    if ($DryRun) {
        Write-Host "  +----------------------------------+" -ForegroundColor Yellow
        Write-Host "  |  !! DRY-RUN MODE - NO CHANGES   |" -ForegroundColor Yellow
        Write-Host "  |  Nothing will be installed or    |" -ForegroundColor Yellow
        Write-Host "  |  written to your system.         |" -ForegroundColor Yellow
        Write-Host "  +----------------------------------+" -ForegroundColor Yellow
        Write-Host ""
    }

    Start-Sleep -Milliseconds 200

    # Author block
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  Designed & built by  " -NoNewline -ForegroundColor DarkGray
    Write-Host "JustifiedWin" -NoNewline -ForegroundColor Cyan
    Write-Host "                              |" -ForegroundColor DarkGray
    Write-Host "  |  Contact:              " -NoNewline -ForegroundColor DarkGray
    Write-Host "justin@ozarkstacks.com" -NoNewline -ForegroundColor Green
    Write-Host "                         |" -ForegroundColor DarkGray
    Write-Host "  |  Powered by:           " -NoNewline -ForegroundColor DarkGray
    Write-Host "OpenCode (SST)" -NoNewline -ForegroundColor White
    Write-Host "  +  " -NoNewline -ForegroundColor DarkGray
    Write-Host "OhMyOpenCode" -NoNewline -ForegroundColor Magenta
    Write-Host "               |" -ForegroundColor DarkGray
    Write-Host "  +-----------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Start-Sleep -Milliseconds 300

    # Matrix drip
    $pool = [char[]]"01アイウエオカキクケコサシスセソタチツテトナニヌネノ"
    $drip  = -join (1..68 | ForEach-Object { $pool[(Get-Random -Maximum $pool.Length)] })
    $drip2 = -join (1..68 | ForEach-Object { $pool[(Get-Random -Maximum $pool.Length)] })
    Write-Host "  $drip"  -ForegroundColor DarkGreen
    Start-Sleep -Milliseconds 80
    Write-Host "  $drip2" -ForegroundColor DarkGreen
    Start-Sleep -Milliseconds 80
    Write-Host ""

    # Loading bars
    Show-LoadingBar "Initializing runtime........" 600
    Show-LoadingBar "Loading agent manifest......" 500
    Show-LoadingBar "Booting deployment engine..." 700
    Write-Host ""

    # Blink then ready
    Write-Host "  " -NoNewline
    Blink-Cursor -Times 4
    Write-Host "  " -NoNewline -ForegroundColor DarkGray
    Type-Line "SYSTEM READY. Starting deployment..." -Color Green -DelayMs 28
    Write-Host ""
    Start-Sleep -Milliseconds 500
}

Show-Splash

# --------------------------------------------------
# Step 1: Prerequisites
# --------------------------------------------------

Write-Header "STEP 1 -- Prerequisites"

if ($DryRun) {
    Write-Step "[DRY-RUN] Would check for: winget, Node.js, Git, npm"
    Write-Step "[DRY-RUN] Would install any missing tools via winget"
    Write-Ok   "[DRY-RUN] Prerequisites check skipped"
} else {
    if (-not (Test-CommandExists "winget")) {
        Write-Warn "winget not found. Please install App Installer from the Microsoft Store, then re-run."
        Write-Host "  https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor DarkGray
        exit 1
    }
    Write-Ok "winget found ($((winget --version).Trim()))"

    if (-not (Test-CommandExists "node")) {
        Install-WithWinget "OpenJS.NodeJS.LTS" "Node.js LTS"
    } else {
        Write-Ok "Node.js found ($(node --version))"
    }

    if (-not (Test-CommandExists "git")) {
        Install-WithWinget "Git.Git" "Git"
    } else {
        Write-Ok "Git found ($(git --version))"
    }

    if (-not (Test-CommandExists "npm")) {
        Write-Fail "npm not found even after Node install. Please restart your terminal and re-run."
        exit 1
    }
    Write-Ok "npm found ($(npm --version))"
}

# --------------------------------------------------
# Step 2: Install OpenCode CLI
# --------------------------------------------------

Write-Header "STEP 2 -- OpenCode CLI"

if ($DryRun) {
    Write-Step "[DRY-RUN] Would run: npm install -g opencode-ai@latest"
    Write-Ok   "[DRY-RUN] OpenCode CLI install skipped"
} else {
    if (Test-CommandExists "opencode") {
        Write-Ok "OpenCode already installed (v$(opencode --version 2>$null))"
        Write-Step "Upgrading to latest..."
        npm install -g opencode-ai@latest --silent
    } else {
        Write-Step "Installing OpenCode CLI globally..."
        npm install -g opencode-ai@latest
    }
    if (-not (Test-CommandExists "opencode")) {
        Write-Fail "OpenCode install failed. Check npm output above."
        exit 1
    }
    Write-Ok "OpenCode installed (v$(opencode --version))"
}

# --------------------------------------------------
# Step 3: Config directory
# --------------------------------------------------

Write-Header "STEP 3 -- Config Directory"

$configDir = Join-Path $env:USERPROFILE ".config\opencode"
if ($DryRun) {
    Write-Step "[DRY-RUN] Would create (if missing): $configDir"
    Write-Ok   "[DRY-RUN] Config directory step skipped"
} else {
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Ok "Created $configDir"
    } else {
        Write-Ok "Config dir exists: $configDir"
    }
}

# --------------------------------------------------
# Step 4: Install oh-my-openagent plugin
# --------------------------------------------------

Write-Header "STEP 4 -- OhMyOpenCode Plugin"

if ($DryRun) {
    Write-Step "[DRY-RUN] Would run: npm install oh-my-openagent@latest"
    Write-Ok   "[DRY-RUN] Plugin install skipped"
} else {
    Write-Step "Installing oh-my-openagent@latest into config dir..."
    Push-Location $configDir
    npm install oh-my-openagent@latest --save 2>&1 | Out-Null
    Pop-Location
    if (Test-Path (Join-Path $configDir "node_modules\oh-my-openagent")) {
        Write-Ok "oh-my-openagent installed."
    } else {
        Write-Fail "oh-my-openagent install failed. Check npm output."
        exit 1
    }
}

# --------------------------------------------------
# Step 5: Write opencode.json
# --------------------------------------------------

Write-Header "STEP 5 -- opencode.json"

Write-Step "Prompting for GitHub Personal Access Token..."
Write-Host "    (github.com > Settings > Developer settings > Personal access tokens)" -ForegroundColor DarkGray
Write-Host "    Recommended scopes: repo, read:org, read:user" -ForegroundColor DarkGray

if ($DryRun) {
    $githubPat = "ghp_DRYRUN_PLACEHOLDER"
    Write-Ok "[DRY-RUN] GitHub PAT prompt skipped -- using placeholder"
} else {
    $githubPat = Prompt-Secret "GitHub PAT"
}

$opencodeJsonPath = Join-Path $configDir "opencode.json"
$opencodeJsonContent = @"
{
  "`$schema": "https://opencode.ai/config.json",
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
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$githubPat"
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
"@

if ($DryRun) {
    Write-Step "[DRY-RUN] Would write opencode.json to: $opencodeJsonPath"
    Write-Host $opencodeJsonContent -ForegroundColor DarkGray
    Write-Ok "[DRY-RUN] File write skipped"
} else {
    $opencodeJsonContent | Set-Content -Path $opencodeJsonPath -Encoding UTF8
    Write-Ok "Written: $opencodeJsonPath"
}

# --------------------------------------------------
# Step 6: Write oh-my-openagent.json
# --------------------------------------------------

Write-Header "STEP 6 -- oh-my-openagent.json"

$omoJsonPath = Join-Path $configDir "oh-my-openagent.json"
$omoJsonContent = @"
{
  "`$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus":       { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3.1-pro-preview" }] },
    "oracle":         { "model": "anthropic/claude-opus-4-6",    "fallback_models": [{ "model": "google/gemini-3.1-pro-preview", "variant": "high" }] },
    "explore":        { "model": "anthropic/claude-haiku-4-5" },
    "multimodal-looker": { "model": "opencode/gpt-5-nano" },
    "prometheus":     { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "metis":          { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "momus":          { "model": "anthropic/claude-sonnet-4-6",  "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] },
    "atlas":          { "model": "anthropic/claude-sonnet-4-6" },
    "sisyphus-junior":{ "model": "anthropic/claude-haiku-4-5",   "fallback_models": [{ "model": "google/gemini-3-flash-preview" }] }
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
"@

if ($DryRun) {
    Write-Step "[DRY-RUN] Would write oh-my-openagent.json to: $omoJsonPath"
    Write-Ok   "[DRY-RUN] File write skipped"
} else {
    $omoJsonContent | Set-Content -Path $omoJsonPath -Encoding UTF8
    Write-Ok "Written: $omoJsonPath"
}

# --------------------------------------------------
# Step 7: API Keys
# --------------------------------------------------

Write-Header "STEP 7 -- API Keys"

Write-Host ""
Write-Host "  You need keys for Anthropic, Google, and OpenAI." -ForegroundColor White
Write-Host "  Press Enter to skip any provider (you can add it later via the opencode UI)." -ForegroundColor DarkGray
Write-Host ""

$authData = @{}

if ($DryRun) {
    Write-Step "[DRY-RUN] Would prompt for: Anthropic, Google, and OpenAI API keys"
    Write-Step "[DRY-RUN] Would write auth.json to: $env:USERPROFILE\.local\share\opencode\auth.json"
    Write-Ok   "[DRY-RUN] API key prompts and auth.json write skipped"
} else {
    Write-Host "  [Anthropic]  console.anthropic.com > API Keys" -ForegroundColor White
    $anthropicKey = Prompt-Secret "Anthropic API key (sk-ant-...)" "(leave blank to skip)"

    Write-Host ""
    Write-Host "  [Google]     aistudio.google.com > Get API Key" -ForegroundColor White
    $googleKey = Prompt-Secret "Google API key (AIza...)" "(leave blank to skip)"

    Write-Host ""
    Write-Host "  [OpenAI]     platform.openai.com > API Keys  (optional -- or log in via opencode UI)" -ForegroundColor White
    $openaiKey = Prompt-Secret "OpenAI API key (sk-...)" "(leave blank to skip)"

    if ($anthropicKey -and $anthropicKey.Trim() -ne "") {
        $authData["anthropic"] = @{ type = "api"; key = $anthropicKey.Trim() }
    }
    if ($googleKey -and $googleKey.Trim() -ne "") {
        $authData["google"] = @{ type = "api"; key = $googleKey.Trim() }
    }
    if ($openaiKey -and $openaiKey.Trim() -ne "") {
        $authData["openai"] = @{ type = "api"; key = $openaiKey.Trim() }
    }

    if ($authData.Count -gt 0) {
        $dataDir = Join-Path $env:USERPROFILE ".local\share\opencode"
        if (-not (Test-Path $dataDir)) {
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        }
        $authPath = Join-Path $dataDir "auth.json"
        $authData | ConvertTo-Json -Depth 3 | Set-Content -Path $authPath -Encoding UTF8
        Write-Ok "auth.json written to $authPath"
    } else {
        Write-Warn "No API keys entered. Run opencode and use the built-in auth flow to add providers."
    }
}

# --------------------------------------------------
# Step 8: Workspace Directory
# --------------------------------------------------

Write-Header "STEP 8 -- Workspace Directory"

Write-Host ""
Write-Host "  The filesystem MCP server is scoped to a single directory." -ForegroundColor White
Write-Host "  Default: $env:USERPROFILE\Documents" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) {
    $workspacePath = Join-Path $env:USERPROFILE "Documents"
    Write-Step "[DRY-RUN] Would prompt for workspace directory"
    Write-Step "[DRY-RUN] Would default to: $workspacePath"
    Write-Step "[DRY-RUN] Would patch filesystem MCP path in opencode.json"
    Write-Ok   "[DRY-RUN] Workspace step skipped"
} else {
    $customWorkspace = Read-Host "  Enter workspace path (or press Enter for default)"
    if ($customWorkspace -and $customWorkspace.Trim() -ne "") {
        $workspacePath = $customWorkspace.Trim()
    } else {
        $workspacePath = Join-Path $env:USERPROFILE "Documents"
    }

    if (-not (Test-Path $workspacePath)) {
        New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
        Write-Ok "Created workspace: $workspacePath"
    } else {
        Write-Ok "Workspace: $workspacePath"
    }

    $rawJson = Get-Content $opencodeJsonPath -Raw
    $escapedPath = $workspacePath -replace '\\', '\\\\'
    $rawJson = $rawJson -replace "WORKSPACE_PATH_PLACEHOLDER", $escapedPath
    $rawJson | Set-Content -Path $opencodeJsonPath -Encoding UTF8
    Write-Ok "opencode.json updated with workspace path."
}

# --------------------------------------------------
# Done
# --------------------------------------------------

Write-Header "DONE"

Write-Host ""
if ($DryRun) {
    Write-Host "  DRY-RUN COMPLETE -- Nothing was installed or written." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  What WOULD have happened:" -ForegroundColor White
    Write-Host "    1. Checked/installed: winget, Node.js, Git, npm" -ForegroundColor DarkGray
    Write-Host "    2. Installed: opencode-ai@latest (global npm)" -ForegroundColor DarkGray
    Write-Host "    3. Created:   $env:USERPROFILE\.config\opencode\" -ForegroundColor DarkGray
    Write-Host "    4. Installed: oh-my-openagent@latest (plugin)" -ForegroundColor DarkGray
    Write-Host "    5. Written:   opencode.json  (with GitHub PAT + MCP config)" -ForegroundColor DarkGray
    Write-Host "    6. Written:   oh-my-openagent.json  (agent + category models)" -ForegroundColor DarkGray
    Write-Host "    7. Written:   auth.json  (Anthropic / Google / OpenAI keys)" -ForegroundColor DarkGray
    Write-Host "    8. Set workspace dir and patched filesystem MCP path" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  To run for real, omit the -DryRun flag:" -ForegroundColor White
    Write-Host "    .\deploy-opencode.ps1" -ForegroundColor Cyan
} else {
    Write-Host "  Everything is installed and configured." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Quick start:" -ForegroundColor White
    Write-Host "    cd `"$workspacePath`"" -ForegroundColor DarkGray
    Write-Host "    opencode" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Config files:" -ForegroundColor White
    Write-Host "    $opencodeJsonPath" -ForegroundColor DarkGray
    Write-Host "    $omoJsonPath" -ForegroundColor DarkGray
    if ($authData.Count -gt 0) {
        Write-Host "    $(Join-Path $env:USERPROFILE '.local\share\opencode\auth.json')" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  If providers are missing, run opencode and use the built-in login flow." -ForegroundColor DarkGray
}
Write-Host ""

# Restore original terminal encoding
[Console]::OutputEncoding = $prevCodePage