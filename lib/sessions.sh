## lib/sessions.sh - Live session wrappers (remote + multiplexer)

# --- Environment Packer ---
# Creates a transportable tarball of CLE environment for remote sessions
_clepak () {
	RH=${CLE_RD/\/.*/}
	RD=${CLE_RD/$RH\//}

	if [ "$CLE_WS" ]; then
		cd "$RH"
		RC=${CLE_RC/$RH\//}
		TW=${CLE_TW/$RH\//}
		EN=${CLE_ENV/$RH\//}
	else
		RH=/var/tmp/$USER
		mkdir -m 0755 -p "$RH/$RD" 2>/dev/null && cd "$RH" || cd
		RC=$RD/rc-$CLE_FHN
		TW=$RD/tw-$CLE_FHN
		EN=$RD/env-$CLE_FHN

		command cp -f "$CLE_RC" "$RC"

		# Pack directories (lib, modules, themes, commands, user)
		local _SD
		for _SD in lib modules themes commands user; do
			local _SRC="$CLE_RD/$_SD"
			local _DST="$RD/$_SD"
			[ -d "$_SRC" ] || continue
			mkdir -p "$_DST"

			if [ "$_SD" = "modules" ] && [ -n "$CLE_REMOTE_MODULES" ]; then
				for _M in $CLE_REMOTE_MODULES; do
					[ -f "$_SRC/mod-$_M" ] && command cp -f "$_SRC/mod-$_M" "$_DST/"
				done
			else
				command cp -f "$_SRC"/* "$_DST/" 2>/dev/null
			fi
		done

		command cp -f "$CLE_TW" "$TW" 2>/dev/null

		echo "# environment $CLE_USER@$CLE_FHN" >"$EN"
		_clevdump "CLE_SRE|CLE_P..|^_C." >>"$EN"
		_clevdump "$CLE_EXP" >>"$EN"
		cat "$CLE_AL" >>"$EN" 2>/dev/null

		# Set VIMINIT for remote sessions
		[ -f "$CLE_RD/user/vimrc" ] && echo "export VIMINIT='source $RH/$RD/user/vimrc'" >>"$EN"
	fi

	if [ "$1" ]; then
		local _DIRS=""
		for _SD in lib modules themes commands user; do
			[ -d "$RD/$_SD" ] && _DIRS="$_DIRS $RD/$_SD"
		done
		C64=$(eval tar chzf - "$RC" "$TW" "$EN" $_DIRS 2>/dev/null | base64 | tr -d '\n\r ')
	fi
}

# --- Remote Session ---

## `lssh [opts] [usr@]host` - SSH with CLE environment propagation
## Options: -J jumphost   proxy through jump host
##          --clean        remove CLE from remote /var/tmp
##          -p h1 h2 -- cmd   parallel execution across hosts
lssh () (
	[ "$1" ] || { cle help lssh; return 1; }

	case "$1" in
	--clean)
		shift
		[ "$1" ] || { echo "Usage: lssh --clean <host>"; return 1; }
		echo "Cleaning CLE from $1..."
		command ssh "$1" "rm -rf /var/tmp/\$USER/.cle-* 2>/dev/null && echo 'Cleaned' || echo 'Nothing to clean'"
		return ;;

	--diff)
		shift
		[ "$1" ] || { echo "Usage: lssh --diff <host>"; return 1; }
		echo "Comparing CLE with $1..."
		local REMOTE_VER
		REMOTE_VER=$(command ssh "$1" "[ -f /var/tmp/\$USER/.cle-*/rc ] && sed -n 's/^#\* version: //p' /var/tmp/\$USER/.cle-*/rc || echo 'not installed'" 2>/dev/null)
		echo "  Local:  $CLE_VER"
		echo "  Remote: $REMOTE_VER"
		return ;;

	-p|--parallel)
		shift
		local HOSTS="" CMD=""
		while [ "$1" ] && [ "$1" != "--" ]; do
			HOSTS="$HOSTS $1"
			shift
		done
		[ "$1" = "--" ] && shift
		CMD="$*"
		[ -z "$HOSTS" -o -z "$CMD" ] && {
			echo "Usage: lssh -p host1 host2 ... -- command"
			return 1
		}
		if command -v tmux >/dev/null 2>&1; then
			local _FIRST=1 _SN="lssh-parallel-$$"
			for H in $HOSTS; do
				if [ $_FIRST -eq 1 ]; then
					tmux new-session -d -s "$_SN" "echo '=== $H ==='; ssh $H '$CMD'; echo '---done---'; read"
					_FIRST=0
				else
					tmux split-window -t "$_SN" "echo '=== $H ==='; ssh $H '$CMD'; echo '---done---'; read"
					tmux select-layout -t "$_SN" tiled
				fi
			done
			tmux attach-session -t "$_SN"
		else
			for H in $HOSTS; do
				echo "=== $H ==="
				command ssh "$H" "$CMD"
				echo "--------------------------------------"
			done
		fi
		return ;;
	esac

	# Standard lssh with CLE propagation
	_clepak tar

	# SSH multiplexing for faster repeated connections
	# Uses %C (hash of %l%h%p%r) to keep socket path short for long hostnames
	local _MUX_OPTS=""
	if [ "${CLE_SSH_MUX:-1}" = 1 ]; then
		local _MUX_DIR="/tmp/.ssh-mux-$USER"
		mkdir -p "$_MUX_DIR" 2>/dev/null
		chmod 700 "$_MUX_DIR" 2>/dev/null
		_MUX_OPTS="-o ControlMaster=auto -o ControlPath=$_MUX_DIR/%C -o ControlPersist=10m"
	fi

	command ssh -t $_MUX_OPTS "$@" "
		H=/var/tmp/\$USER; mkdir -m 755 -p \$H; cd \$H
		[ \"\$OSTYPE\" = darwin ] && D=D || D=d
		echo $C64|base64 -\$D|tar xzmf - 2>/dev/null
		exec \$H/$RC -m $CLE_ARG"
)

## `lsudo [user]` - sudo wrapper (default: root)
lsudo () (
	_clepak
	sudo -i -u ${1:-root} "$RH/$RC" $CLE_ARG
)

## `lsu [user]` - su wrapper
lsu () (
	_clepak
	local S=
	[[ $OSTYPE =~ [Ll]inux ]] && S="-s /bin/sh"
	eval su $S -l ${1:-root} "$RH/$RC"
)

## `lksu [user]` - ksu wrapper
lksu () (
	_clepak
	ksu ${1:-root} -a -c "cd;$RH/$RC"
)

# --- GNU Screen ---

## `lscreen [name]`    - start or reattach CLE screen session
## `lscreen -j [name]` - join another user's screen session
lscreen () (
	NM=$CLE_USER${1:+-$1}
	[ "$1" = -j ] && NM=${2:-.}
	SCRS=$(screen -ls | sed -n "/$NM/s/^[ \t]*\([0-9]*\.[^ \t]*\)[ \t]*.*/\1/p")
	NS=$(echo "$SCRS" | grep -c '[^ ]')
	reset

	if [ "$NS" = 0 ]; then
		[ "$1" = -j ] && echo "No screen to join" && return 1
		SCF=$CLE_D/screenrc
		SN=$CLE_TTY-CLE.$NM
		_clerh @ "$CLE_TTY" "screen -S $SN"
		_clescrc >"$SCF"
		screen -c "$SCF" -S "$SN" "$CLE_RC"
	else
		if [ "$NS" = 1 ]; then
			SN=$SCRS
		else
			_clebold "${_CU}Current '$NM' sessions:"
			PS3="$_CL choose # to join: $_CN"
			select SN in $SCRS; do [ "$SN" ] && break; done
		fi
		_clerh @ "$CLE_TTY" "screen -x $SN"
		screen -S "$SN" -X echo "$CLE_USER joining"
		screen -x "$SN"
	fi
)

# Generate GNU Screen configuration
_clescrc () {
cat <<-EOS
	source $HOME/.screenrc
	altscreen on
	autodetach on
	termcapinfo xterm* ti@:te@
	bindkey "^[[1;2D" prev
	bindkey "^[[1;2C" next
	defscrollback 9000
	hardstatus alwayslastline
	hardstatus string '%{= Kk} %-w%{Wk}%n %t%{-}%+w %-=%{+b Y}$CLE_SHN%{G} %c'
	bind c screen $CLE_RC
	bind ^c screen $CLE_RC
EOS
cat <<<"$CLE_SCRC"
}

# --- tmux (Enhanced) ---

## `ltmux [name]`    - start or reattach CLE tmux session
## `ltmux -j [name]` - join another user's tmux session
ltmux () (
	NM=$CLE_USER${1:+-$1}
	[ "$1" = -j ] && NM=${2:-.}

	TMUXS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "$NM")
	NTS=$(echo "$TMUXS" | grep -c '[^ ]')

	if [ "$NTS" -eq 0 ] 2>/dev/null; then
		[ "$1" = -j ] && echo "No tmux session to join" && return 1
		SN=$CLE_TTY-CLE.$NM
		TCF=$CLE_D/tmuxrc
		_cletmuxcf >"$TCF"
		_clerh @ "$CLE_TTY" "tmux -S $SN"
		tmux -f "$TCF" new-session -s "$SN" "$CLE_RC"
	else
		if [ "$NTS" -eq 1 ] 2>/dev/null; then
			SN=$TMUXS
		else
			_clebold "${_CU}Current '$NM' sessions:"
			PS3="$_CL choose # to join: $_CN"
			select SN in $TMUXS; do [ "$SN" ] && break; done
		fi
		_clerh @ "$CLE_TTY" "tmux attach $SN"
		tmux attach-session -t "$SN"
	fi
)

# Generate tmux configuration with CLE integration
_cletmuxcf () {
cat <<-EOT
	# CLE-generated tmux config
	set -g default-command "$CLE_RC"
	set -g history-limit 50000
	set -g mouse on
	set -g escape-time 0
	set -g status-style "bg=black,fg=white"
	set -g status-left "#[fg=green,bold]$CLE_USER@$CLE_SHN "
	set -g status-right "#[fg=yellow]%H:%M"
	set -g status-left-length 30
	set -g status-interval 15

	# New windows/panes inherit CLE
	bind c new-window "$CLE_RC"
	bind ^c new-window "$CLE_RC"
	bind '"' split-window -v "$CLE_RC"
	bind % split-window -h "$CLE_RC"

	# Shift-arrow to switch windows
	bind -n S-Left previous-window
	bind -n S-Right next-window
EOT
}

# --- Multiplexer Auto-Detection ---

## `lmux [name]` - auto-detect tmux/screen and use whichever is available
lmux () {
	if command -v tmux >/dev/null 2>&1; then
		ltmux "$@"
	elif command -v screen >/dev/null 2>&1; then
		lscreen "$@"
	else
		echo "Neither tmux nor screen found. Install one to use session management."
		return 1
	fi
}
