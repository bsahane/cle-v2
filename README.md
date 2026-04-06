<h1 align="center">
  <br>
  CLE v2 — Command Live Environment
  <br>
</h1>

<p align="center">
  <strong>A modular shell enhancement framework for bash and zsh</strong>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-installation">Install</a> •
  <a href="#-modules">Modules</a> •
  <a href="#-remote-ssh">Remote SSH</a> •
  <a href="#-configuration">Config</a> •
  <a href="#-aliases">Aliases</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Shell-bash%20%7C%20zsh-green" alt="Shell">
  <img src="https://img.shields.io/badge/OS-Linux%20%7C%20macOS-blue" alt="OS">
  <img src="https://img.shields.io/badge/Modules-45-orange" alt="Modules">
  <img src="https://img.shields.io/badge/License-GPL%20v2-red" alt="License">
  <img src="https://img.shields.io/badge/Version-2026--04--06-brightgreen" alt="Version">
</p>

---

## What is CLE?

CLE transforms your terminal into a powerful, consistent environment that follows you everywhere — including remote servers via SSH. It provides a colorful prompt, persistent aliases, rich command history, 45 extension modules, and seamless remote session propagation.

```
Local Machine ──lssh──> Remote Server ──lssh──> Another Server
     │                       │                       │
     └── Same prompt, same aliases, same tools, same vimrc
```

### Why CLE?

| Problem | CLE Solution |
|---------|-------------|
| Different shell configs on every server | `lssh` propagates your entire environment |
| Forgetting useful commands | 45 modules with 225+ functions always available |
| Inconsistent prompt across machines | Configurable prompt themes that travel with you |
| Lost command history on remote | Rich history with timestamps, durations, exit codes |
| No vim config on remote servers | Vimrc automatically packed and activated via VIMINIT |

---

## Features

### Core

- **Modular Architecture** — 9 core libraries + 45 optional modules
- **Cross-Shell** — Full support for both bash and zsh
- **Cross-Platform** — Linux and macOS with OS-specific optimizations
- **Prompt Themes** — 6 built-in themes with git, k8s, venv, and SSH agent indicators
- **Rich History** — Every command logged with timestamp, duration, exit code, and working directory
- **Persistent Aliases** — 40+ built-in aliases that survive sessions and follow you remotely
- **Remote Propagation** — Your entire shell environment travels via `lssh`

### Prompt

```
┌─[0] 14:30:45 bsahane server.example.com
│ ~/projects/myapp:main
└─$ _
```

Available themes: `rh` (Red Hat), `twoline`, `triliner`, `minimal`, `git`, `ops`

Set with: `cle prompt <theme>`

### Modern CLI Integration

CLE auto-detects and integrates with modern Rust-powered CLI replacements:

| Classic | Modern | Auto-detected? |
|---------|--------|:-:|
| `ls` | `eza` | Yes |
| `cat` | `bat` | Yes |
| `cd` | `zoxide` | Yes |
| Prompt | `starship` | Yes |

---

## Installation

### Quick Install

```bash
git clone git@github.com:bsahane/cle-v2.git ~/cle-v2
cd ~/cle-v2
./install.sh
```

### What install.sh does

1. Copies CLE to `~/.cle-$USER/`
2. Adds a source line to your `~/.bashrc` or `~/.zshrc`
3. Preserves your existing user aliases and tweaks

### Manual Install

```bash
git clone git@github.com:bsahane/cle-v2.git ~/.cle-$(whoami)
echo '[ -f ~/.cle-'$(whoami)'/rc ] && . ~/.cle-'$(whoami)'/rc' >> ~/.zshrc
source ~/.zshrc
```

### Verify

```bash
cle doctor    # Health check
cle help      # All commands
cle profile   # Startup timing
```

---

## Modules

CLE ships with **45 extension modules** organized by category:

### Development

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-git** | `gipul` `gipus` `gicom` `gilog` `giout` `giundo` `giamend` `giwho` `gisize` | Git workflow shortcuts |
| **mod-project** | `project` `todos` | Auto-detect project stack, find TODOs |
| **mod-workspace** | `activate` `wsnew` `wsclone` `wslist` `wsgo` `wsinfo` | Project workspace manager |
| **mod-devtools** | `port` `ports` `json` `calc` `weather` `cheat` `epoch` `httpcode` | Developer utilities |

### System Administration

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-k8s** | `kpods` `klog` `kexec` `kctx` `kevents` `kres` | Kubernetes shortcuts |
| **mod-openshift** | `oclogin` `ocpods` `ocdeploy` `ocdash` + 10 more | Red Hat OpenShift management |
| **mod-docker** | `dps` `dlog` `dexec` `dstop` `dclean` `dimages` | Container management |
| **mod-sysinfo** | `sysinfo` `top5` `myip` `speedtest` | System information dashboard |
| **mod-process** | `pof` `killport` `zombies` `waitfor` | Process management |
| **mod-net** | `lportcheck` `lportlisten` `lsysload` | Network diagnostics |
| **mod-port** | `portscan` `portcheck` `waitport` `killport` `listening` `portfwd` | Port management and scanning |
| **mod-log** | `logf` `logc` `logerr` `logstat` `logtop` `logbetween` `logwatch` | Log analysis and tailing |
| **mod-env** | `envs` `dotenv` `dotenv-show` `dotenv-diff` `pathls` `pathadd` `pathclean` | Environment variable management |

### DevOps & Infrastructure

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-ansible** | `aplay` `acheck` `aping` `afacts` `arun` `ainv` `alint` `avault-*` `aroles` | Ansible workflow shortcuts |
| **mod-terraform** | `tfinit` `tfplan` `tfapply` `tfdestroy` `tfstate` `tfws` `tflint` `tfsec` | Terraform/OpenTofu IaC |
| **mod-http** | `GET` `POST` `PUT` `DELETE` `HEAD` `httptime` `headers` `jwt` `curlb` `waiturl` | HTTP/API testing |
| **mod-json** | `jval` `jfmt` `jmin` `jq.` `jkeys` `jlen` `jdiff` `jgrep` `j2y` `y2j` | JSON processing utilities |

### Security & Crypto

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-cert** | `lcert` `lcert-bulk` | SSL/TLS certificate inspection |
| **mod-ssh** | `sshkeys` `sshload` `sshagent` `sshfp` | SSH agent management |
| **mod-hash** | `md5` `sha256` `hashfile` `verify` `checkdir` | Hashing utilities |
| **mod-guard** | Safety wrappers | Dangerous command protection |

### Productivity

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-fzf** | `ff` `fd` `fkill` `fenv` `fmod` `fh` | FZF-powered fuzzy tools |
| **mod-todo** | `ltodo` | Universal todolist with contexts |
| **mod-note** | `note` | Quick terminal notes with tagging |
| **mod-remind** | `timer` `stopwatch` `pomodoro` `remind` `countdown` | Terminal timers |
| **mod-sudo** | `please` `sudoedit` + Esc-Esc widget | Quick sudo prefix |
| **mod-oops** | `oops` `fuck` | Thefuck-inspired command corrector |
| **mod-backup** | `bak` `bak-list` `bak-restore` `bak-clean` | Timestamped backups |

### AI & Intelligence

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-ai** | `ai` `ai-cmd` `ai-explain` `ai-fix` | AI command generation (Ollama/API) |
| **mod-audit** | `audit` `audit-stats` `audit-export` | Command audit trail |
| **mod-timeline** | `timeline` `activity` | Session visualization |

### File & Text

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-strings** | `upper` `lower` `trim` `runx` `watchit` `randstr` `randpw` | Text manipulation |
| **mod-files** | `biggest` `newest` `dupes` `swap` `compare` `filetypes` | File utilities |
| **mod-extract** | `extract` `mktar` `mkzip` | Universal archive extractor |
| **mod-clip** | `clip` `clpaste` `clipfile` | Cross-platform clipboard |

### Sharing & Transfer

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-serve** | `serve` `serve-upload` `qr` | Quick HTTP server |
| **mod-transfer** | `transfer` `share` `paste-text` | File sharing (transfer.sh) |

### Visual & Terminal

| Module | Commands | Description |
|--------|----------|-------------|
| **mod-colors** | `colors16` `colors256` `truecolor` `colortest` | Terminal color display |
| **mod-rec** | `lrec` `lrec-list` `lrec-play` | Terminal recording |
| **mod-starship** | `cle starship` | Starship prompt integration |
| **mod-zoxide** | `j` `ji` | Smart directory jumping |

---

## Remote SSH

CLE's killer feature is **seamless remote session propagation**. Your entire environment — prompt, aliases, modules, vimrc — travels with you.

### Basic Usage

```bash
lssh user@remote-host          # SSH with CLE environment
lssh -J jumphost user@target   # Via jump host
lsudo                          # sudo with CLE (default: root)
lsu admin                      # su with CLE
ltmux                          # tmux with CLE in every pane
lscreen                        # GNU screen with CLE
lmux                           # Auto-detect tmux/screen
```

### Advanced SSH

```bash
lssh --clean host              # Remove CLE from remote /var/tmp
lssh --diff host               # Compare local vs remote CLE version
lssh -p h1 h2 h3 -- uptime    # Parallel execution (tmux panes)
```

### Selective Module Packing

```bash
# Only send specific modules to remote (lighter pack)
export CLE_REMOTE_MODULES="git ssh cert"
lssh user@remote
```

### SSH Connection Multiplexing

Enabled by default. Repeated SSH connections to the same host reuse the existing connection for faster startup.

```bash
export CLE_SSH_MUX=0    # Disable if needed
```

---

## Aliases

### ls Family

| Alias | Command | Purpose |
|-------|---------|---------|
| `l` | `ls -lrth` | Long, reverse time, human sizes |
| `la` | `ls -lrthA` | Same + hidden files |
| `ll` | `ls -lh` | Long listing |
| `lS` | `ls -lhS` | Sort by size (largest first) |
| `lSr` | `ls -lhSr` | Sort by size (smallest first) |
| `lt` | `ls -lht` | Sort by time (newest first) |
| `ld` | `ls -ld */` | Directories only |
| `l.` | `ls -lhd .[^.]*` | Hidden files only |
| `l1` | `ls -1` | One per line |

### Navigation

| Command | Purpose |
|---------|---------|
| `..` / `...` / `....` | Go up 1/2/3 directories |
| `mkcd dir` | Create and cd into directory |
| `take dir` | Same as mkcd (OMZ compat) |
| `bd parent` | Jump back to named parent dir |
| `up 3` | Go up N directories |
| `bm name` | Named bookmarks |
| `go name` | Jump to bookmark |
| `fcd` | Fuzzy cd (fzf) |

### Git

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status -sb` |
| `gl` | `git log --oneline -15` |
| `gd` | `git diff` |
| `gp` | `git pull` |

### Utility

`cls` (clear), `path` (show PATH), `now` (datetime), `week` (week number), `psg` (process grep), `topmem`, `topcpu`, `reload` (source rc), `mounted`, `tf` (tail -f)

---

## Configuration

### Prompt Customization

```bash
cle color 5Bg           # Set color scheme
cle p0 '\u'             # User in prompt part 0
cle p1 '\h'             # Host in prompt part 1
cle p2 '\w'             # Working directory
cle prompt triliner     # Use preset theme
cle rprompt on          # Enable right prompt (git/venv)
cle transient on        # Simplify previous prompt lines (zsh)
```

### Feature Toggles

```bash
cle audit on                    # Enable command audit logging
cle debug on                    # Enable set -x tracing
export CLE_NOTIFY_THRESHOLD=30  # Desktop notification after 30s commands
export CLE_GUARD=1              # Enable dangerous command protection
```

### Workspace Configuration

```bash
# In your tw (tweaks) file:
CLE_WS_DIRS="$HOME/Developer $HOME/GitLab $HOME/Projects"
CLE_WS_VENVDIR="$HOME/venvs"
CLE_WS_EDITOR="cursor"
```

### Editing Configuration

```bash
cle cf ed        # Edit host-specific config
cle ed tw        # Edit tweaks file
cle vi           # Edit CLE vimrc
aa -e            # Edit all aliases interactively
cle switch save work  # Save current config as 'work' profile
cle switch work       # Switch to 'work' profile
```

---

## Workspace Manager

Inspired by organized workspace patterns, CLE includes a project workspace manager:

```bash
activate myproject       # Find project, activate venv, cd into it
wsnew api --venv --git   # Create new project with venv + git
wsclone git@... --venv   # Clone + venv + auto-install deps
wslist                   # List all projects with stack detection
wsgo                     # FZF-powered project selector
wsinfo                   # Current project details
wsrecent                 # Recently accessed projects
wsvenv myproject         # Create venv for existing project
```

---

## History

CLE's rich history records every command with metadata:

```bash
h                     # Recent history
hh                    # Rich history viewer
hh -w                 # History from current directory only
hh -e                 # Show only errors
hh -m                 # Show only today
hh --since 2026-04-01 # Since date
hh -x json            # Export as JSON
hh -S                 # Statistics
hhi                   # FZF interactive fuzzy search
hgrep "pattern"       # Quick history grep
```

---

## Health Check

```bash
$ cle doctor

=== CLE Health Check ===
  Version:     2026-04-06 (v2-modular)
  Shell:       zsh
  RC File:     /home/user/.cle-user/rc
  Modules:     38

  Tools:
  fzf          installed
  tmux         installed
  git          installed
  eza          installed
  bat          installed
  starship     installed
```

---

## Writing Custom Modules

Create `modules/mod-mymod`:

```bash
##
## ** mod-mymod: My custom module **
#* version: 2026-04-06

## `mycmd <arg>` - does something useful
mycmd () {
    echo "Hello from mod-mymod: $*"
}
```

Or scaffold with: `cle mod new mymod`

The module will be auto-loaded on next shell startup and included in remote `lssh` sessions.

---

## Project Structure

```
cle-v2/
├── rc                    # Entry point (bootstrapper)
├── install.sh            # Deployment script
├── lib/                  # Core libraries (9 files)
│   ├── init.sh           # Variable initialization
│   ├── utils.sh          # Shared utilities
│   ├── colors.sh         # Terminal color table
│   ├── prompt.sh         # Prompt engine
│   ├── history.sh        # Rich history system
│   ├── aliases.sh        # Alias management + 40+ defaults
│   ├── navigation.sh     # Directory navigation
│   ├── sessions.sh       # Remote session propagation
│   └── cle.sh            # CLE command center
├── modules/              # 45 extension modules
├── themes/               # Prompt themes + palettes
├── commands/             # CLE subcommands
├── user/                 # User data (vimrc, aliases, tweaks)
└── docs/                 # Architecture documentation
```

---

## Credits

- **Original Author**: Michael Arbet (marbet@redhat.com)
- **Maintainer**: Bhushan Sahane (bsahane@redhat.com)
- **License**: GNU GPL v2

CLE was originally created as a single-file shell enhancer. v2 reimagines it as a fully modular framework with 45 extension modules, cross-platform support, and modern CLI integration.

---

<p align="center">
  <sub>Built with care for the command line</sub>
</p>
