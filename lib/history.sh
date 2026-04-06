## lib/history.sh - Rich history system with timing and exit codes

CLE_HTF='%F %T'
HISTTIMEFORMAT=${HISTTIMEFORMAT:-$CLE_HTF }

# --- Pre/Post Command Hooks ---

_PST='${PIPESTATUS[@]}'
[ "$ZSH_NAME" ] && _PST='${pipestatus[@]}'
[ "$BASH_VERSINFO" = 3 ] && _PST='$?'

# Called after each command completes (before prompt is drawn)
precmd () {
	eval "_EC=$_PST"
	[[ $_EC =~ [1-9] ]] || _EC=0
	local IFS S DT C
	unset IFS

	if [ $BASH ]; then
		C=$_HN
		history -a
	else
		C=$(fc -lt ";$CLE_HTF;" -1)
		C=${C#*;}
	fi
	DT=${C/;*}
	C=${C/$DT;}
	C="${C#"${C%%[![:space:]]*}"}"

	if [[ $C =~ ^\# ]]; then
		_clerh '#' "$PWD" "$C"
	elif [ "$_HT" ]; then
		S=$((SECONDS - ${_HT:-$SECONDS}))
		_clerh "$DT" $S "$_EC" "$PWD" "$C"
		[ "$_EC" = 0 ] && _CE="" || _CE="$_Ce"
		# Desktop notification for long commands
		if [ "$S" -gt "${CLE_NOTIFY_THRESHOLD:-0}" ] 2>/dev/null && [ "${CLE_NOTIFY_THRESHOLD:-0}" -gt 0 ]; then
			_cle_notify "$C" "$S" "$_EC"
		fi
		# Audit trail hook
		typeset -f _cle_audit_hook >/dev/null 2>&1 && _cle_audit_hook
		_HT=
	else
		_CE=''
		_EC=0
	fi
	[ $BASH ] && trap _clepreex DEBUG
}

# Called before each command executes
preexec () {
	_HT=$SECONDS
}

# Bash DEBUG trap to detect command execution
if [ $BASH ]; then
	history -r "$HISTFILE"
	_HP=$(HISTTIMEFORMAT=";$CLE_HTF;" history 1)
	_HP=${_HP#*;}
	_clepreex () {
		_HN=$(HISTTIMEFORMAT=";$CLE_HTF;" history 1)
		_HN=${_HN#*;}
		echo -n "$_CN"
		[ "$_HP" = "$_HN" ] && return
		_HP=$_HN
		trap "" DEBUG
		preexec "$BASH_COMMAND"
	}
fi

# --- Rich History Record ---
# Format: date;session-pid;duration;exitcode;directory;command
_clerh () {
	local DT SC REX ID V VD W
	case $# in
	3) DT=$(date "+$CLE_HTF"); SC='' ;;
	4) DT=$(date "+$CLE_HTF"); SC=$1; shift ;;
	5) DT=$1; SC=$2; shift; shift ;;
	esac

	REX="^cd\ |^cd$|^-$|^\.\.$|^\.\.\.$|^aa$|^lscreen|^ltmux|^h$|^hh$|^hh\ "
	[[ $3 =~ $REX || -n $_NORH ]] && unset _NORH && return

	W=${2/$HOME/\~}
	ID="$DT;$CLE_USER-$$"
	REX='^\$[A-Za-z0-9_]+'

	case "$3" in
	echo*)
		echo -E "$ID;$SC;$1;$W;$3"
		for V in $3; do
			if [[ $V =~ $REX ]]; then
				V=${V/\$/}
				VD=$(_clevdump "$V")
				echo -E "$ID;;$;;${VD:-unset $V}"
			fi
		done ;;
	xx)
		echo -E "$ID;;*;$W;" ;;
	\#*)
		echo -E "$ID;;#;$W;$3" ;;
	*)
		echo -E "$ID;$SC;$1;$W;$3" ;;
	esac
} >>"$CLE_HIST"

# --- History Viewers ---

## `h` - shell history wrapper with colorized output
h () (
	([ $BASH ] && HISTTIMEFORMAT=";$CLE_HTF;" history "$@" \
	 || fc -lt ";$CLE_HTF;" "$@") | (
		IFS=';'
		while read -r N DT C; do
			echo -E "$_CB$N$_Cb $DT $_CN$_CL$C$_CN"
		done
	)
)

## `hh [opts] [search] [limit]` - rich history viewer
## Options: -m (mine) -d (today) -t (this session) -s (success only)
##          -w (current dir) -n (narrow) -c (commands only) -f (folders)
##          -l (less) -S (stats) -e (errors only) -x json|csv (export)
##          --since "YYYY-MM-DD" (date filter)
hh () {
	(
		OUTF='_clehhout'
		DISP=""
		S=""
		EXPORT_FMT=""
		SINCE_DATE=""

		# Handle --since before getopts
		local _ARGS=()
		while [ $# -gt 0 ]; do
			case "$1" in
			--since)
				shift; SINCE_DATE=$1; shift ;;
			*)
				_ARGS+=("$1"); shift ;;
			esac
		done
		set -- "${_ARGS[@]}"

		while getopts "mdtsncflSewx:" O; do
			case $O in
			m) S=$S"; /;$CLE_USER/!d" ;;
			d) S=$S"; /^$(date "+%F") /!d" ;;
			t) S=$S"; /;$CLE_USER-$$;/!d" ;;
			s) S=$S"; /.*;.*;.*;0;.*/!d" ;;
			e) S=$S"; /.*;.*;.*;0;/d; /.*;.*;.*;@;/d; /.*;.*;.*;#;/d; /.*;.*;.*;\*;/d" ;;
			w) local _WD="${PWD/$HOME/\~}"; S=$S"; /;${_WD//\//\\/};/!d" ;;
			n) OUTF='_clehhout n' ;;
			c) OUTF="sed -n 's/^[^;]*;[^;]*;[^;]*;[0-9]*;[^;]*;\(.*\)/\1/p' |uniq" ;;
			f) OUTF="sed -n 's/^[^;]*;[^;]*;[^;]*;[0-9]*;\([^;]*\);.*/\1/p' |sort|uniq" ;;
			l) DISP="|less -r +G" ;;
			S) _clehhstats; return ;;
			x) EXPORT_FMT=$OPTARG ;;
			*) cle help hh; return ;;
			esac
		done
		shift $((OPTIND - 1))

		# Date filter
		[ -n "$SINCE_DATE" ] && S=$S"; /^$SINCE_DATE/!{/^[0-9][0-9][0-9][0-9]-/!d; /^$SINCE_DATE/!{H;g;/^$SINCE_DATE/!d}}"

		# Export mode
		if [ -n "$EXPORT_FMT" ]; then
			case "$EXPORT_FMT" in
			json)
				OUTF='_clehhexport_json' ;;
			csv)
				echo "date,session,duration,exit_code,directory,command"
				OUTF='_clehhexport_csv' ;;
			*)
				echo "Export format: json or csv"; return 1 ;;
			esac
		fi

		SEARCH_TERM=""
		LIMIT=""
		if [ $# -eq 1 ]; then
			[[ $1 =~ ^[0-9]+$ ]] && LIMIT=$1 || SEARCH_TERM=$1
		elif [ $# -eq 2 ]; then
			SEARCH_TERM=$1; LIMIT=$2
		fi

		[ -n "$SEARCH_TERM" ] && S=$S"; /${SEARCH_TERM//\//\\}/!d"

		if [ -n "$SEARCH_TERM" ]; then
			if [ -n "$LIMIT" ]; then
				eval "tail -n +1 $CLE_HIST | sed -e '$S' | tail -n $LIMIT | $OUTF $DISP"
			else
				eval "tail -n +1 $CLE_HIST | sed -e '$S' | $OUTF $DISP"
			fi
		else
			eval "tail -n ${LIMIT:-1000} $CLE_HIST | $OUTF $DISP"
		fi
	)
}

# Export history as JSON
_clehhexport_json () {
	echo "["
	local _first=1
	while IFS=';' read -r dt sess dur ec dir cmd; do
		[ -z "$dt" ] && continue
		[ $_first -eq 1 ] && _first=0 || echo ","
		printf '  {"date":"%s","session":"%s","duration":"%s","exit_code":"%s","directory":"%s","command":"%s"}' \
			"$dt" "$sess" "$dur" "$ec" "$dir" "$cmd"
	done
	echo ""
	echo "]"
}

# Export history as CSV
_clehhexport_csv () {
	while IFS=';' read -r dt sess dur ec dir cmd; do
		[ -z "$dt" ] && continue
		printf '"%s","%s","%s","%s","%s","%s"\n' "$dt" "$sess" "$dur" "$ec" "$dir" "$cmd"
	done
}

# Colorized output filter for rich history
_clehhout () (
	NRW=$1
	set -f
	while read -r L; do
		IFS=';'
		set -- $L
		case $4 in
		0)          CE=$_Cg; CC=$_CN ;;
		@)          CE=$_Cc; CC=$_Cc ;;
		'#'|$|'*')  CE=$_CY; CC=$_Cy ;;
		*)          CE=$_Cr; CC=$_CN ;;
		esac
		if [ "$NRW" ]; then
			printf " $CE%-9s $CC%-20s: $_CL" "$4" "$5"
		else
			printf "$_CB%s $_Cb%-13s $_CB%3s $CE%-5s $CC%-10s: $_CL" "$1" "$2" "$3" "$4" "$5"
		fi
		shift 5
		printf "%s\n" "$*"
	done
)

## `hh -S` - history statistics
_clehhstats () (
	echo "$_CL=== CLE History Statistics ===$_CN"
	echo ""
	echo "$_CU Top 20 Commands:$_Cu"
	awk -F';' 'NF>=6{print $6}' "$CLE_HIST" | sort | uniq -c | sort -rn | head -20
	echo ""
	echo "$_CU Error Rate:$_Cu"
	local total errors
	total=$(wc -l < "$CLE_HIST")
	errors=$(awk -F';' '$4 != 0 && $4 != "" && $4 != "@" && $4 != "#" && $4 != "*"' "$CLE_HIST" | wc -l)
	[ "$total" -gt 0 ] && echo "  Total: $total | Errors: $errors | Rate: $((errors * 100 / total))%" || echo "  No history"
	echo ""
	echo "$_CU Most Active Directories:$_Cu"
	awk -F';' 'NF>=5{print $5}' "$CLE_HIST" | sort | uniq -c | sort -rn | head -10
)

## `hhi` - interactive fuzzy history search (requires fzf)
hhi () {
	if ! command -v fzf >/dev/null 2>&1; then
		echo "fzf not installed. Install with: brew install fzf (macOS) or apt install fzf (Linux)"
		return 1
	fi

	local selected
	selected=$(tail -n 10000 "$CLE_HIST" | \
		awk -F';' 'NF>=6{
			ec=$4; dir=$5; cmd=$6;
			for(i=7;i<=NF;i++) cmd=cmd";"$i;
			if(ec=="0") mark="  ";
			else if(ec=="@") mark="@ ";
			else if(ec=="#") mark="# ";
			else mark="! ";
			printf "%s %s | %-30s | %s\n", mark, $1, dir, cmd
		}' | \
		fzf --ansi --tac --no-sort \
			--header="Exit | Date                | Directory                      | Command" \
			--preview='echo {}' \
			--bind='ctrl-r:toggle-sort' \
			--prompt="history> ")

	[ -z "$selected" ] && return

	local cmd
	cmd=$(echo "$selected" | sed 's/^[^|]*|[^|]*| *//')

	if [ "$ZSH_NAME" ]; then
		print -z "$cmd"
	else
		# bash: put on readline buffer
		READLINE_LINE="$cmd"
		READLINE_POINT=${#cmd}
		# if not in readline context, just print for copy
		[ -z "$READLINE_LINE" ] && echo "$cmd"
	fi
}

## `hgrep <pattern>` - quick grep through rich history
hgrep () {
	[ -z "$1" ] && { echo "Usage: hgrep <pattern>"; return 1; }
	grep --color=auto -i "$*" "$CLE_HIST" | tail -30
}

# zsh: allow # comments on command line
[ "$ZSH_NAME" ] && '#' () { true; }
