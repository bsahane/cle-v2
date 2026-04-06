## lib/aliases.sh - Persistent alias management

## `aa`         - show all aliases
## `aa -s`      - save aliases to file
## `aa -e`      - edit aliases in editor
## `aa -f pat`  - find alias by pattern
## `aa a='b'`   - create and save new alias
aa () {
	local AED=$CLE_AL.ed
	local Z=${ZSH_NAME:+-L}
	case "$1" in
	"")
		builtin alias $Z | sed "s/^alias \([^=]*\)=\(.*\)/$_CL\1$_CN\t\2/" ;;
	-s)
		builtin alias $Z >"$CLE_AL" ;;
	-e)
		builtin alias $Z >"$AED"
		vi "$AED"
		[ "$ZSH_NAME" ] && builtin unalias -m '*' || builtin unalias -a
		. "$AED" ;;
	-f)
		shift
		builtin alias $Z | grep -i "$*" | sed "s/^alias \([^=]*\)=\(.*\)/$_CL\1$_CN\t\2/" ;;
	*=*)
		builtin alias "$*"
		aa -s ;;
	*)
		builtin alias "$*" ;;
	esac
}

## `_cle_os_alias linux_alias darwin_alias` - set alias by platform
_cle_os_alias () {
	case $OSTYPE in
	linux*)  builtin alias "$1" ;;
	darwin*) builtin alias "$2" ;;
	esac
}

# Override alias/unalias builtins to auto-save
alias () {
	if [ -n "$1" ]; then
		aa "$@"
	else
		builtin alias
	fi
}

unalias () {
	[ "$1" = -a ] && cp "$CLE_AL" "$CLE_AL.bk"
	builtin unalias "$@"
	aa -s
}

# ---- Hardcoded default aliases (always available, including remote) ----

# ls family -- works with ls, eza, or any ls replacement
builtin alias l='ls -lrth'
builtin alias la='ls -lrthA'
builtin alias ll='ls -lh'
builtin alias lla='ls -lhA'
builtin alias lS='ls -lhS'
builtin alias lSr='ls -lhSr'
builtin alias lt='ls -lht'
builtin alias ltr='ls -lhtr'
builtin alias ld='ls -ld */'
builtin alias l.='ls -lhd .[^.]*'
builtin alias l1='ls -1'
builtin alias lR='ls -lhR'

# Directory shortcuts
builtin alias ....='cd ../../..'
builtin alias .....='cd ../../../..'
builtin alias md='mkdir -p'
builtin alias rd='rmdir'

# Common operations with safe defaults
builtin alias cp='cp -iv'
builtin alias mv='mv -iv'
builtin alias ln='ln -iv'

# Disk and system
builtin alias df='df -h'
builtin alias du='du -h'
builtin alias dud='du -d 1 -h'
builtin alias duf='du -sh *'

# Grep family
builtin alias egrep='grep -E --color=auto'
builtin alias fgrep='grep -F --color=auto'

# Output formatting
builtin alias cls='clear'
builtin alias path='echo -e "${PATH//:/\\n}"'
builtin alias now='date "+%Y-%m-%d %H:%M:%S"'
builtin alias week='date +%V'
builtin alias timestamp='date +%s'

# File finding shortcuts
builtin alias ff.='find . -type f -name'
builtin alias fd.='find . -type d -name'

# Quick edit & view
builtin alias v='vi'
builtin alias less='less -R'
builtin alias tf='tail -f'
builtin alias head='head -n 20'
builtin alias tail='tail -n 20'

# Process management
builtin alias psg='ps aux | grep -v grep | grep -i'
builtin alias topmem='ps aux --sort=-%mem 2>/dev/null | head -11 || ps aux -m | head -11'
builtin alias topcpu='ps aux --sort=-%cpu 2>/dev/null | head -11 || ps aux -r | head -11'

# Network shortcuts
builtin alias ping='ping -c 5'
builtin alias fastping='ping -c 10 -i 0.2'
builtin alias headers='curl -I'

# History shortcut
builtin alias hist='history | tail -30'

# Git shortcuts (lightweight, detailed ones in mod-git)
builtin alias g='git'
builtin alias gs='git status -sb'
builtin alias gl='git log --oneline -15'
builtin alias gd='git diff'
builtin alias gp='git pull'

# Misc handy
builtin alias tree='tree -C --dirsfirst 2>/dev/null || find . -print | sed -e "s;[^/]*/;|__ ;g;s;__|; ;g"'
builtin alias reload='source $CLE_RC'
builtin alias weather='curl -s "wttr.in/?format=3"'
builtin alias mounted='mount | column -t'
# Note: ports is provided as a richer function by mod-devtools

# Platform-specific defaults
case $OSTYPE in
linux*)
	builtin alias free='free -h'
	builtin alias lx='ls -lhX'
	builtin alias open='xdg-open'
	;;
darwin*)
	builtin alias flush='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
	builtin alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
	builtin alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
	builtin alias lscleanup='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder'
	;;
esac
