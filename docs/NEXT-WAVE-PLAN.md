# CLE v2 - Next Wave Improvement Plan

> **Date**: 2026-04-06
> **Method**: BMad Brainstorming + Technical Research + Market Research + Domain Research
> **Focus**: Enterprise features, AI integration, community-readiness

---

## BMAD BRAINSTORMING SESSION - Next Wave Ideas

### Category: AI & Intelligence Integration

1. **`cle ai "explain error"`** - Pipe last command's stderr to LLM for explanation
2. **`cle suggest`** - AI-powered command suggestions based on history patterns
3. **`cle fix`** - Automatically suggest fix for last failed command
4. **Smart history search** - Semantic search over rich history using embeddings
5. **Command prediction** - Show ghost text of predicted next command (like fish shell)
6. **Error pattern detection** - Alert when repeated errors suggest systemic issue
7. **Natural language commands** - `cle do "show me disk usage over 1GB"` -> generates command

### Category: Enterprise & Team Features

8. **Shared module registry** - `cle mod install <name>` from community repo
9. **Team config sync** - Share CLE config across team via git repo
10. **Audit trail** - Immutable command log for compliance (separate from history)
11. **Role-based module loading** - Different module sets for dev/ops/security roles
12. **Centralized history** - Ship rich history to central log aggregator
13. **Policy enforcement** - Block/warn on dangerous commands (rm -rf /, etc.)
14. **Multi-user CLE management** - Admin tool to deploy CLE across fleet

### Category: Modern Shell UX

15. **Transient prompt** - Full prompt on current line, compact for scrollback
16. **Syntax highlighting** - Highlight commands as typed (like fish/zsh-syntax-highlighting)
17. **Auto-suggestions** - Show dim suggestion from history (like fish)
18. **Right-side prompt** - Git status, time, or other info on the right
19. **Inline directory preview** - Show `ls` preview when cd'ing
20. **Command palette** - `Ctrl+P` fuzzy finder for CLE commands and modules
21. **Smart cd** - `z` / `zoxide` integration for frecency-based directory jumping
22. **Multi-line editing** - Better multi-line command support
23. **Undo/redo** - Command-level undo for file operations

### Category: Remote & Cloud

24. **SSH multiplexing** - Reuse SSH connections for faster `lssh`
25. **Container awareness** - Detect running inside Docker/Podman and adapt
26. **Cloud shell support** - AWS CloudShell, GCP Cloud Shell, Azure Cloud Shell
27. **Kubernetes exec** - `lkexec pod` to enter pod with CLE environment
28. **Remote file sync** - `lsync host:/path` bidirectional file sync
29. **Bastion host management** - Smart jump host routing
30. **Remote module execution** - Run module functions on remote without full lssh

### Category: Observability & Analytics

31. **Command dashboard** - Terminal-based dashboard of command metrics
32. **Time tracking** - Track time spent per project/directory
33. **Productivity insights** - Weekly/daily command pattern analysis
34. **Error rate alerting** - Notify when error rate exceeds threshold
35. **Session timeline** - Visual timeline of commands with durations
36. **Heatmap** - When are you most active in terminal?

---

## TECHNICAL RESEARCH: Priority Next Features

### 1. Zoxide Integration (Smart cd)

**Impact**: HIGH - Replaces manual bookmarks for frequent directories
**Effort**: LOW - Just wrap `z` and hook into CLE navigation

```bash
# In lib/navigation.sh or as mod-zoxide:
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init $CLE_SH)"
fi
```

### 2. SSH Connection Multiplexing

**Impact**: HIGH - Dramatically speeds up repeated lssh to same host
**Effort**: MEDIUM - Needs ControlMaster/ControlPath management

```bash
# In sessions.sh, before ssh:
_cle_ssh_mux () {
    local MUX_DIR=$HOME/.ssh/mux
    mkdir -p "$MUX_DIR"
    echo "-o ControlMaster=auto -o ControlPath=$MUX_DIR/%r@%h:%p -o ControlPersist=10m"
}
```

### 3. Container/Pod Awareness

**Impact**: MEDIUM - Many users work inside containers
**Effort**: LOW - Detect and add prompt indicator

```bash
# In prompt.sh:
_cle_prompt_container () {
    [ -f /.dockerenv ] && echo "docker" && return
    [ -f /run/.containerenv ] && echo "podman" && return
    [ -d /run/secrets/kubernetes.io ] && echo "k8s" && return
}
```

### 4. Dangerous Command Guard

**Impact**: HIGH for enterprise - Prevents destructive mistakes
**Effort**: MEDIUM - Needs preexec hook integration

```bash
# Dangerous patterns to warn about:
CLE_DANGEROUS_PATTERNS=(
    'rm -rf /'
    'rm -rf /*'
    'chmod -R 777 /'
    'dd if=.* of=/dev/sd'
    '> /dev/sda'
    'mkfs.*'
)
```

### 5. AI Command Helper (via local LLM or API)

**Impact**: HIGH for productivity
**Effort**: HIGH - Needs API integration or local model

```bash
_cle_ai () {
    local Q="$*"
    # Try ollama first (local), then fall back to API
    if command -v ollama >/dev/null 2>&1; then
        ollama run codellama "Generate a bash command for: $Q. Output only the command."
    elif [ -n "$CLE_AI_API_KEY" ]; then
        curl -s "https://api.openai.com/v1/chat/completions" \
            -H "Authorization: Bearer $CLE_AI_API_KEY" \
            -d '{"model":"gpt-4","messages":[{"role":"user","content":"'"$Q"'"}]}'
    fi
}
```

---

## MARKET RESEARCH: Shell Framework Landscape 2026

### Emerging Trends

1. **AI-native shells** - Warp Terminal, Lacy Shell with built-in LLM
2. **Rust-powered replacements** - nushell, starship, zoxide, eza, bat, fd, ripgrep
3. **Minimal configuration** - Trend away from Oh-My-Zsh bloat toward lean configs
4. **Session persistence** - tmux-resurrect, tmux-continuum becoming standard
5. **Cross-platform** - WSL2, Codespaces, remote dev containers
6. **Observability** - atuin (encrypted history sync), shell analytics

### CLE Positioning

CLE occupies a unique niche: **zero-dependency remote shell propagation** that works across both bash and zsh. No competitor matches this combination:

| Feature | CLE | OMZ | xxh | Starship | nushell |
|---------|-----|-----|-----|----------|---------|
| Bash support | YES | No | YES | YES | No |
| Zsh support | YES | YES | YES | YES | No |
| macOS native | YES | YES | YES | YES | YES |
| Zero-dep remote | YES | No | No | No | No |
| Rich history | YES | No | No | No | YES |
| Module system | YES | YES | No | YES | YES |
| AI integration | Next | No | No | No | No |

### Recommended Strategy

1. **Keep the zero-dependency core** - This is CLE's moat
2. **Add AI helpers as optional module** - Don't require API keys
3. **Integrate with Rust CLI tools** - Detect and use eza/bat/fd when available
4. **Build community module registry** - Like Oh-My-Zsh plugins but lighter
5. **Session persistence** - Integrate with tmux-resurrect for crash recovery

---

## DOMAIN RESEARCH: SysAdmin Workflow Patterns

### Common Workflows CLE Should Optimize

1. **Incident response**: SSH to multiple hosts, check logs, run diagnostics
   - CLE has: `lssh`, `mod-see`, `mod-net`
   - Missing: Parallel log aggregation, incident timeline

2. **Certificate management**: Check expiry, rotate, verify
   - CLE has: `mod-cert` with `lcert`, `lciphertest`
   - Missing: Automated expiry monitoring, bulk cert check

3. **Deployment verification**: SSH to hosts, verify services, check health
   - CLE has: `lssh`, `ext-cmd`, `lcommand`
   - Missing: Health check templates, service status aggregation

4. **DNS troubleshooting**: Query records, compare across resolvers
   - CLE has: `mod-dns` with `lmxcheck`, `ldnslookup`
   - Missing: DNS propagation checker, record diff

5. **Log analysis**: Tail logs, search patterns, correlate events
   - CLE has: `mod-see` with highlighting and counting
   - Missing: Multi-host log correlation, pattern alerting

---

## IMPLEMENTATION ROADMAP - Next Wave

### Phase 5: Smart Integrations (Quick Wins)

| # | Task | Impact | Effort |
|---|------|--------|--------|
| 1 | Zoxide integration (`mod-zoxide`) | High | 30 min |
| 2 | Container awareness in prompt | Medium | 20 min |
| 3 | SSH connection multiplexing | High | 1 hr |
| 4 | Rust CLI tool detection (eza, bat, fd) | Medium | 30 min |
| 5 | Dangerous command guard | High | 1 hr |

### Phase 6: AI & Intelligence

| # | Task | Impact | Effort |
|---|------|--------|--------|
| 6 | `cle ai` with ollama/API | High | 2 hr |
| 7 | Command suggestion from history | Medium | 2 hr |
| 8 | Error explanation pipe | Medium | 1 hr |

### Phase 7: Enterprise & Community

| # | Task | Impact | Effort |
|---|------|--------|--------|
| 9 | Module registry (install from URL) | High | 3 hr |
| 10 | Team config sync via git | Medium | 2 hr |
| 11 | Audit trail mode | Medium | 1 hr |
| 12 | Bulk cert expiry checker | Medium | 1 hr |

### Phase 8: Modern UX

| # | Task | Impact | Effort |
|---|------|--------|--------|
| 13 | Transient prompt | Medium | 2 hr |
| 14 | Right-side prompt | Low | 1 hr |
| 15 | Session timeline visualization | Medium | 2 hr |
| 16 | Productivity insights | Low | 2 hr |

---

## QUICK-START: Phase 5 Implementation Ready

### mod-zoxide (ready to implement)

```bash
# modules/mod-zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init $CLE_SH --cmd cd)"
fi
```

### Container prompt (ready to implement)

Add `^D` escape for container context:
```bash
_cle_prompt_container () {
    [ -f /.dockerenv ] && echo "docker" && return
    [ -f /run/.containerenv ] && echo "podman" && return
    [ -d /run/secrets/kubernetes.io ] && echo "k8s-pod" && return
}
```

### Rust CLI detection (ready to implement)

```bash
# In rc, after platform aliases:
command -v eza >/dev/null 2>&1 && alias ls='eza --color=auto --icons'
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v fd >/dev/null 2>&1 && alias find='fd'
command -v rg >/dev/null 2>&1 && alias grep='rg'
```

---

*Plan generated via BMad Brainstorming + Technical Research + Market Research + Domain Research*
*CLE v2 - Building the future of zero-dependency shell environments*
