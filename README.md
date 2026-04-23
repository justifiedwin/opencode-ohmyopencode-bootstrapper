# OpenCode + OhMyOpenCode Bootstrapper

> One-command setup for [OpenCode](https://opencode.ai) + [OhMyOpenCode](https://github.com/code-yeongyu/oh-my-openagent) on Windows and Mac.
>
> Designed & built by **JustifiedWin** — justin@ozarkstacks.com

---

## What is this?

[OpenCode](https://opencode.ai) is a terminal-based AI coding assistant built by SST.  
[OhMyOpenCode](https://github.com/code-yeongyu/oh-my-openagent) is a configuration framework that supercharges it with a full agent roster, task delegation, and model routing.

This bootstrapper installs and configures everything from scratch — no manual setup required.

---

## What gets installed

| Component | Details |
|---|---|
| **Node.js LTS** | Via winget (Windows) or Homebrew (Mac) |
| **Git** | Via winget / Homebrew if not present |
| **OpenCode CLI** | `opencode-ai@latest` via npm |
| **OhMyOpenCode plugin** | `oh-my-openagent@latest` |
| **opencode.json** | MCP servers: Playwright, GitHub, Memory, Fetch, Filesystem |
| **oh-my-openagent.json** | Full agent + category model config |
| **auth.json** | Your API keys (prompted interactively — never hardcoded) |

### MCP Servers configured

- 🎭 **Playwright** — browser automation
- 🐙 **GitHub** — full GitHub API access
- 🧠 **Memory** — persistent knowledge graph
- 🌐 **Fetch** — web content retrieval
- 📁 **Filesystem** — scoped file read/write

### Agent roster (via OhMyOpenCode)

| Agent | Model | Role |
|---|---|---|
| Sisyphus | claude-sonnet-4-6 | Primary build agent |
| Oracle | claude-opus-4-6 | High-IQ consultant |
| Explore | claude-haiku-4-5 | Codebase search |
| Sisyphus-Junior | claude-haiku-4-5 | Task executor |
| Prometheus / Metis / Momus | claude-sonnet-4-6 | Planning & review |

---

## Windows

### Requirements
- Windows 10 or later
- PowerShell 5.1+ (pre-installed on all modern Windows)
- winget (pre-installed on Windows 11, available via Microsoft Store on Windows 10)

### Run

```powershell
.\deploy-opencode.ps1
```

> The script self-configures execution policy — no manual steps needed.

### Dry run (preview only, no changes made)

```powershell
.\deploy-opencode.ps1 -DryRun
```

---

## Mac

### Requirements
- macOS 10.15 (Catalina) or later
- Terminal access

### Run

```bash
bash deploy-opencode-mac.sh
```

### Dry run (preview only, no changes made)

```bash
bash deploy-opencode-mac.sh --dry-run
```

> Homebrew will be installed automatically if not present.

---

## What the installer asks you for

During setup you'll be prompted for:

| Prompt | Where to get it |
|---|---|
| **GitHub PAT** | github.com → Settings → Developer settings → Personal access tokens |
| **Anthropic API key** | console.anthropic.com → API Keys |
| **Google API key** | aistudio.google.com → Get API Key |
| **OpenAI API key** | platform.openai.com → API Keys *(optional)* |
| **Workspace directory** | Any folder on your machine — defaults to Documents |

All keys are entered interactively and masked. Nothing is hardcoded in the scripts.

---

## After install

```bash
cd ~/Documents   # or your chosen workspace
opencode
```

Log in to any providers you skipped during setup via the OpenCode UI.

---

## License

MIT — free to use, modify, and share.

---

*Built with [OpenCode](https://opencode.ai) + [OhMyOpenCode](https://github.com/code-yeongyu/oh-my-openagent)*
