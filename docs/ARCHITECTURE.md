# CLE v2 Architecture

## Overview

CLE (Command Live Environment) v2 is a modular shell enhancement framework supporting bash and zsh on Linux and macOS. It provides a colorful prompt, persistent aliases, rich command history, seamless remote session propagation, and extensible modules.

## Directory Structure

```
cle-v2/
├── rc                     # Entry point (bootstrapper)
├── lib/                   # Core library (sourced in order)
│   ├── init.sh            # Variable initialization, path setup
│   ├── utils.sh           # Shared utilities (_clebold, _cleask, _clemdf, _cle_notify)
│   ├── colors.sh          # Terminal color table management
│   ├── prompt.sh          # Prompt engine (PS1 building, escapes)
│   ├── history.sh         # Rich history (precmd/preexec hooks, hh/hhi viewers)
│   ├── aliases.sh         # Alias management (aa command, platform helpers)
│   ├── navigation.sh      # cd enhancements (.., ..., xx, cx, bm, go, fcd)
│   ├── sessions.sh        # Session wrappers (lssh, lsudo, lscreen, ltmux, lmux)
│   └── cle.sh             # CLE command center, completions, doctor, profile
├── modules/               # Optional extensions (auto-loaded)
│   ├── mod-ai             # AI command helpers (ollama/API)
│   ├── mod-audit          # Command audit trail with structured logging
│   ├── mod-cert           # SSL/TLS certificate inspection + bulk checker
│   ├── mod-clip           # Cross-platform clipboard integration
│   ├── mod-disk           # Disk and archive utilities
│   ├── mod-dns            # DNS diagnostics
│   ├── mod-fzf            # FZF-powered file finder, process killer, env browser
│   ├── mod-git            # Git shortcuts
│   ├── mod-guard          # Dangerous command protection
│   ├── mod-mail           # Mail server operations
│   ├── mod-net            # Network utilities
│   ├── mod-rec            # Terminal session recording (asciinema/script)
│   ├── mod-see            # Live log viewer with highlighting
│   ├── mod-ssh            # SSH agent and key management
│   ├── mod-starship       # Starship prompt integration
│   ├── mod-timeline       # Session timeline and activity visualization
│   ├── mod-zoxide         # Smart directory jumping (zoxide integration)
│   ├── mod-devtools       # Developer tools (ports, JSON, base64, calc, weather, cheat)
│   ├── mod-sysinfo        # System info dashboard (sysinfo, top5, myip, speedtest)
│   ├── mod-docker         # Container management (dps, dlog, dexec, dclean)
│   ├── mod-extract        # Universal archive extractor (extract, mktar, mkzip)
│   ├── mod-k8s            # Kubernetes shortcuts (kpods, klog, kexec, kctx, kres)
│   ├── mod-oops           # Command correction (oops/fuck - thefuck-inspired)
│   ├── mod-project        # Project detection and info (project, todos)
│   ├── mod-openshift      # Red Hat OpenShift management (14 functions)
│   ├── mod-todo           # Universal todolist (ltodo)
│   ├── mod-backup         # Timestamped backup utilities (bak, bak-list, bak-restore)
│   └── mod-note           # Quick terminal notes with tagging
├── themes/                # Visual customization
│   ├── cle-prompt         # Prompt theme presets
│   └── cle-palette        # Terminal color palettes
├── commands/              # CLE subcommands
│   └── cle-ed             # File editor with backup
├── user/                  # User data (not overwritten on update)
│   ├── al                 # Saved aliases
│   └── tw                 # Per-host tweaks
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md    # This file
│   └── IMPROVEMENT-PLAN-v2.md  # Improvement roadmap
└── install.sh             # Deployment script (POSIX-compatible)
```

## Execution Flow

```
Shell startup -> source rc
  1. Shell detection (bash/zsh)
  2. Path resolution (CLE_RC, CLE_RD, CLE_LIB)
  3. Profile loading (/etc/profile, ~/.bashrc or ~/.zshrc)
  4. Source lib/*.sh in order: init -> utils -> colors -> prompt -> history -> aliases -> navigation -> sessions -> cle
  5. Initialize: _cle_init_vars, _cle_init_host, _cle_init_dirs
  6. Source: env (inherited) -> aliases -> tweaks -> modules
  7. Build prompt: _cledefp -> _cletable -> _cle_load_config -> _cleps -> _cleclr
  8. Set up completions (bash-native or zsh compdef)
  9. Register PROMPT_COMMAND=precmd
```

## Key Mechanisms

### Source-Once Guard (_clexe)
Prevents double-sourcing by tracking loaded files in CLE_EXE.

### Environment Packing (_clepak)
Creates a base64-encoded tarball of rc + lib/ + modules/ + themes/ + commands/ + tw + env for remote SSH transport. Supports selective module packing via `CLE_REMOTE_MODULES`.

### Rich History (_clerh)
Records every command with metadata:
- Timestamp, Session ID, Duration, Exit code, Working directory, Full command text

Format: `date;session;duration;exitcode;directory;command`

### Interactive History (hhi)
fzf-powered fuzzy search through rich history with exit code, directory, and command preview.

### Prompt System
Four configurable prompt parts (P0-P3) plus title (PT), supporting CLE-specific escape sequences translated to the active shell's native escapes. Separate `CLE_PB*` (bash) and `CLE_PZ*` (zsh) overrides.

### Module System
Files matching `mod-*` in CLE_D or CLE_RD/modules/ are auto-sourced. Modules register CLE subcommands by defining `_cle_<name>()` functions.

### Desktop Notifications
Long-running commands trigger desktop notifications when `CLE_NOTIFY_THRESHOLD` is set (seconds). Supports macOS (osascript) and Linux (notify-send).

### Clipboard Integration (mod-clip)
Cross-platform clipboard via `clip` (copy) and `clpaste` (paste). Auto-detects: pbcopy (macOS), xclip/xsel/wl-copy (Linux), clip.exe (WSL).

## Key Variables

| Variable | Purpose |
|----------|---------|
| CLE_RC | Full path to the rc file |
| CLE_RD | Directory containing rc |
| CLE_LIB | Path to lib/ directory |
| CLE_D | Working directory (~/.cle-user) |
| CLE_CF | Host-specific config file |
| CLE_AL | Persistent alias file |
| CLE_TW | Tweak file |
| CLE_HIST | Rich history file |
| CLE_FHN | Fully qualified hostname |
| CLE_SHN | Shortened hostname |
| CLE_USER | CLE user identity |
| CLE_WS | Workspace identifier (remote sessions) |
| CLE_CLR | Current color scheme code |
| CLE_VER | CLE version string |
| CLE_REMOTE_MODULES | Space-separated list of modules to pack for remote (optional) |
| CLE_NOTIFY_THRESHOLD | Seconds threshold for long-command notifications (0=disabled) |
| CLE_RPROMPT | Enable right prompt with git/venv info (0/1, default 0) |
| CLE_TRANSIENT | Enable transient prompt - simplify previous prompt lines (zsh only, 0/1) |
| CLE_AUDIT | Enable command audit logging to CLE_AUDIT_LOG (0/1) |
| CLE_AUDIT_LOG | Path to audit log file (default ~/.cle-audit.log) |
| CLE_GUARD | Enable dangerous command protection (0/1) |
| CLE_AI_MODEL | Ollama model name for AI helper (default llama3.2) |
| CLE_AI_API_KEY | API key for OpenAI-compatible AI backend |
| CLE_AI_API_URL | API URL for AI backend (default OpenAI) |
| CLE_SSH_MUX | Enable SSH connection multiplexing (0/1, default 1) |

## Remote Session Architecture

### Standard SSH Propagation (lssh)
```
Local: _clepak tar -> base64 encode -> ssh -t host "decode | untar | exec rc"
         Contents: rc + lib/ + modules/ + themes/ + commands/ + tw + env
```

### Advanced SSH Features
- `lssh --clean host` - Remove CLE artifacts from remote `/var/tmp`
- `lssh --diff host` - Compare local vs remote CLE version
- `lssh -p h1 h2 -- cmd` - Parallel execution across hosts (tmux panes)
- `CLE_REMOTE_MODULES="git dns"` - Selective module packing

### Multiplexer Integration
- `ltmux` - Full CLE propagation into new tmux windows/panes via `_cletmuxcf`
- `lscreen` - Full CLE propagation into GNU screen windows
- `lmux` - Auto-detect available multiplexer

## Shell Compatibility

| Feature | bash | zsh |
|---------|------|-----|
| Prompt escapes | `\u`, `\h`, `\w` | `%n`, `%m`, `%~` |
| Associative arrays | `declare -A` | `typeset -A` |
| Array key iteration | `${!arr[@]}` | `${(k)arr[@]}` |
| Regex match capture | `BASH_REMATCH` | Portable `sed` |
| Date parsing | `date -d` | `date -j -f` (macOS) |
| Completions | bash-completion + `complete -F` | `compinit` + `compdef` |
| Preexec hook | DEBUG trap | Native `preexec` function |
| Alias listing | `alias` | `alias -L` |

## CLE Commands Reference

```
cle                     Show version info and banner
cle color <scheme>      Set prompt color scheme
cle p0-p3 [string]      Show/define prompt parts
cle title [off|string]  Set window title
cle cf [ed|reset|rev]   Manage host configuration
cle deploy              Hook CLE into shell profile
cle update [branch]     Download and install new CLE version
cle reload [bash|zsh]   Reload CLE (optionally switch shell)
cle mod [new|list]      Module management / scaffolding
cle switch <profile>    Switch between saved config profiles
cle env                 Inspect CLE variables
cle doctor              Health check
cle profile             Startup time profiling
cle rprompt [on|off]    Toggle right prompt (git, venv info)
cle transient [on|off]  Toggle transient prompt (zsh only)
cle audit [on|off]      Toggle command audit logging
cle debug [on|off]      Toggle verbose tracing (set -x)
cle help [function]     Show help
cle doc                 Online documentation
cle ed <target>         Edit config files (tw, cf, bashrc, zshrc, etc.)
cle starship <cmd>      Starship prompt integration
```

## Writing Modules

Create a file `modules/mod-<name>` with:
1. Header comment with `##` help strings
2. Function definitions (use `l` prefix for sysadmin tools)
3. Optional `_cle_<name>()` function to register as CLE subcommand

Scaffold a new module with: `cle mod new <name>`

Modules are auto-sourced on shell startup and included in remote session packs.
