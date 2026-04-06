# CLE v2 - Comprehensive Improvement Plan

> **Author**: Bhushan Sahane (bsahane@redhat.com)
> **Date**: 2026-04-06
> **Method**: BMad Architect + Technical Research + Domain Research + Brainstorming
> **Scope**: Mac ZSH compatibility, Remote SSH tools, New features

---

## Executive Summary

CLE v2 (Command Live Environment) has been successfully modularized from a monolithic ~960-line `rc` into a clean `rc` + 9 lib files + 8 modules architecture. This plan addresses three key areas:

1. **Mac ZSH Compatibility** - 8 identified bugs/gaps preventing full zsh parity on macOS
2. **Remote SSH Tool Improvements** - Enhance `_clepak`, `lssh`, and remote utilities for better SSH workflows
3. **New Features** - Modern CLI UX improvements (fzf history, notifications, clipboard, profiling)

---

## PART 1: MAC ZSH COMPATIBILITY FIXES

### Issue 1.1: `mod-see` uses bash-only `declare -A` (CRITICAL)

**File**: `modules/mod-see`
**Problem**: `declare -A WORD_COUNT` creates an associative array using bash syntax. While zsh accepts `declare -A`, the array expansion `${!WORD_COUNT[@]}` (bash) differs from zsh's `${(k)WORD_COUNT}`.
**Fix**: Use portable syntax with `typeset -A` and conditional key iteration.

### Issue 1.2: `lcommand` uses `BASH_REMATCH` (CRITICAL)

**File**: `modules/mod-mail` (`lcommand` function)
**Problem**: `BASH_REMATCH` doesn't exist in zsh. Zsh uses `match` array (or `MATCH`/`MBEGIN`/`MEND` with `=~`).
**Fix**: Use portable regex extraction with `sed` or conditional variable names.

### Issue 1.3: `lcert` date parsing not macOS-compatible (HIGH)

**File**: `modules/mod-cert` (`lcert` function)
**Problem**: `date -d "$end_date"` is GNU date (Linux). macOS BSD date uses `-j -f` format. Current fallback may fail with certain date formats from OpenSSL.
**Fix**: Use a robust cross-platform date parser function.

### Issue 1.4: `install.sh` uses bash-only `read -p` (MEDIUM)

**File**: `install.sh`
**Problem**: `read -p "prompt"` is bash-specific. Zsh uses `read "?prompt"`.
**Fix**: Use `printf` + `read` (POSIX) or `_cleask` pattern.

### Issue 1.5: Zsh completions are minimal (MEDIUM)

**File**: `lib/cle.sh` (`_cle_setup_completions`)
**Problem**: Bash gets full SSH hostname completion for `lssh`; zsh only gets `compdef lssh=ssh` which may not load if `compinit` hasn't run yet.
**Fix**: Ensure `compinit` is loaded before `compdef`, add zsh-native completion for `cle` subcommands.

### Issue 1.6: `_clevdump` output differs between bash/zsh (LOW)

**File**: `lib/utils.sh`
**Problem**: `typeset` output format varies between bash (`declare -- VAR="val"`) and zsh (`VAR=val`). The `awk` parser may miss variables in one shell.
**Fix**: Normalize to consistent format.

### Issue 1.7: `sed -i` behavior on macOS (LOW)

**File**: `lib/navigation.sh` (`bm` function)
**Problem**: `sed -i` on macOS requires `sed -i ''` (empty extension). GNU sed on Linux accepts `sed -i` directly.
**Fix**: Use portable `sed` + `mv` pattern (already partially done in `bm -d`).

### Issue 1.8: `preexec` hook in zsh (LOW)

**File**: `lib/history.sh`
**Problem**: Zsh has a native `preexec` hook but CLE defines its own `preexec()` function. If zsh's hook system is active, there could be conflicts.
**Fix**: Use `add-zsh-hook` if available, fall back to function override.

---

## PART 2: REMOTE SSH TOOL IMPROVEMENTS

### Feature 2.1: Pack themes/ and commands/ for remote sessions

**File**: `lib/sessions.sh` (`_clepak`)
**Problem**: `_clepak` copies `lib/` and `modules/` but not `themes/` or `commands/`. Remote sessions lack `cle-ed`, prompt themes, and palette control.
**Fix**: Include `themes/` and `commands/` in the tarball.

### Feature 2.2: Selective module packing (`CLE_REMOTE_MODULES`)

**File**: `lib/sessions.sh` (`_clepak`)
**Problem**: All modules are packed for remote transfer, increasing payload size unnecessarily.
**Fix**: Add `CLE_REMOTE_MODULES` variable to selectively pack only needed modules.

### Feature 2.3: Remote CLE cleanup (`lssh --clean`)

**File**: `lib/sessions.sh`
**Problem**: CLE artifacts in `/var/tmp/$USER` on remote hosts accumulate over time.
**Fix**: Add `lssh --clean host` to remove CLE artifacts from remote hosts.

### Feature 2.4: Multi-hop SSH support (`lssh -J`)

**File**: `lib/sessions.sh`
**Problem**: `lssh` doesn't handle jump hosts. Users must manually chain SSH.
**Fix**: Support `-J jumphost` flag that propagates through ProxyJump.

### Feature 2.5: Parallel multi-host execution (`lssh -p`)

**File**: `lib/sessions.sh`
**Problem**: No way to run commands across multiple hosts simultaneously.
**Fix**: Add `lssh -p host1 host2 -- command` for parallel execution in tmux panes.

### Feature 2.6: Remote environment diff

**File**: New function in `lib/sessions.sh`
**Problem**: Users can't easily see what differs between local and remote CLE.
**Fix**: Add `lssh --diff host` to compare CLE versions and config.

### Feature 2.7: SSH connection profiles

**File**: New functionality
**Problem**: Complex SSH options must be typed every time.
**Fix**: Read `~/.ssh/config` Host entries and integrate with `lssh` completion.

---

## PART 3: NEW FEATURES

### Feature 3.1: fzf-powered interactive history (`hhi`)

**File**: `lib/history.sh`
**Impact**: HIGH - Most requested modern CLI feature
**Implementation**: New `hhi` function that pipes rich history through fzf with preview showing exit code, duration, and working directory.

### Feature 3.2: Long command notification

**File**: `lib/history.sh` (in `precmd`)
**Impact**: MEDIUM - Quality of life for sysadmins
**Implementation**: After command completes, if duration exceeds `CLE_NOTIFY_THRESHOLD` (default 30s), send desktop notification.

### Feature 3.3: Cross-platform clipboard (`clip`)

**File**: New module `modules/mod-clip`
**Impact**: MEDIUM - Common need
**Implementation**: `clip` function that detects `pbcopy` (macOS), `xclip`/`xsel` (Linux), `clip.exe` (WSL).

### Feature 3.4: Startup profiling (`cle profile`)

**File**: `lib/cle.sh`
**Impact**: MEDIUM - Developer experience
**Implementation**: Source each lib file with timing, report slowest components.

### Feature 3.5: Platform-conditional aliases

**File**: `lib/aliases.sh`
**Impact**: LOW - Cleanliness
**Implementation**: `_cle_platform_alias` helper that branches on `$OSTYPE`.

### Feature 3.6: Module scaffolding (`cle mod new`)

**File**: `lib/cle.sh`
**Impact**: LOW - Developer experience
**Implementation**: Generate a skeleton `mod-<name>` file with proper headers.

---

## IMPLEMENTATION PRIORITY

| Phase | Task | Impact | Effort | Status |
|-------|------|--------|--------|--------|
| 1.1 | Fix mod-see zsh compat | Critical | 30 min | TODO |
| 1.2 | Fix lcommand BASH_REMATCH | Critical | 15 min | TODO |
| 1.3 | Fix lcert date parsing | High | 30 min | TODO |
| 1.4 | Fix install.sh for zsh | Medium | 15 min | TODO |
| 1.5 | Improve zsh completions | Medium | 30 min | TODO |
| 1.6 | Fix _clevdump for zsh | Low | 15 min | TODO |
| 1.7 | Fix sed -i for macOS | Low | 10 min | TODO |
| 1.8 | Fix preexec zsh hooks | Low | 20 min | TODO |
| 2.1 | Pack themes/commands remote | High | 30 min | TODO |
| 2.2 | Selective module packing | Medium | 30 min | TODO |
| 2.3 | lssh --clean | Medium | 20 min | TODO |
| 2.4 | Multi-hop SSH | Medium | 45 min | TODO |
| 2.5 | Parallel multi-host | Medium | 1 hr | TODO |
| 3.1 | fzf interactive history | High | 45 min | TODO |
| 3.2 | Long command notification | Medium | 20 min | TODO |
| 3.3 | Clipboard integration | Medium | 20 min | TODO |
| 3.4 | Startup profiling | Medium | 30 min | TODO |
| 3.5 | Platform-conditional aliases | Low | 15 min | TODO |
| 3.6 | Module scaffolding | Low | 20 min | TODO |

---

## COMPETITIVE ANALYSIS

| Feature | CLE v2 | Oh-My-Zsh | xxh | Starship |
|---------|--------|-----------|-----|----------|
| Bash + Zsh | YES | No (zsh only) | YES | YES |
| Zero-dep remote propagation | YES | No | No (needs Python) | No |
| Rich history w/ metadata | YES | No | No | No |
| Module system | YES | YES (plugins) | No | YES |
| macOS native | Partial -> Full | YES | YES | YES |
| fzf integration | Adding | YES (plugin) | No | No |
| Async prompt | Adding | YES (plugin) | No | YES |
| SSH env sync | YES | No | YES | No |

CLE's unique value: **zero-dependency SSH environment propagation** with rich history, working across both bash and zsh, without requiring any pre-installation on remote hosts.

---

*Plan generated via BMad Architect + Technical Research + Brainstorming*
*CLE upstream: https://github.com/micharbet/CLE (Zodiac branch)*
