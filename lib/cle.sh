## lib/cle.sh - CLE command & control center + completions

## ** CLE command & control **
cle () {
	local C I P S N
	C=$1; shift

	# Check for function extensions (_cle_*)
	if typeset -f "_cle_$C" >/dev/null 2>&1; then
		"_cle_$C" "$@"
		return $?
	fi

	# Check for command files (commands/cle-*, themes/cle-*, or $CLE_D/cle-*)
	local _CF
	for _CF in "$CLE_RD/commands/cle-$C" "$CLE_RD/themes/cle-$C" "$CLE_D/cle-$C"; do
		if [ -f "$_CF" ]; then
			. "$_CF" "$@"
			return $?
		fi
	done

	case $C in
	color)  ## `cle color COLOR` - set prompt color scheme
		[ "$1" ] && _cleclr "$1" && _clesave ;;

	p?)     ## `cle p0-p3 [str]` - show/define prompt parts
		I=${C:1:1}
		if [ "$1" ]; then
			P=B; [[ $* =~ % && -n "$ZSH_NAME" ]] && P=Z || unset CLE_PZ$I
			S=$*
			eval "[ \"\$S\" != \"\$CLE_P$I\" ] && { CLE_P$P$I='$*';_clepcp;_cleps;_clesave; }" || :
		else
			_clevdump "CLE_P$I"
		fi ;;

	title)  ## `cle title off|string` - set window title
		case "$1" in
		off) CLE_PT='' ;;
		'')  _clepcp ;;
		*)   cle pT "$*" ;;
		esac
		_cleps ;;

	cf)     ## `cle cf [ed|reset|rev]` - manage configuration
		case "$1" in
		ed)    vi "$CLE_CF" && . "$CLE_RC" ;;
		reset) mv -f "$CLE_CF" "$CLE_CF-bk" ;;
		rev)   cp "$CLE_CF-bk" "$CLE_CF" ;;
		"")
			if [ -f "$CLE_CF" ]; then
				_clebold "$_CU$CLE_CF:"
				cat "$CLE_CF"
			else
				echo "Default/Inherited configuration"
			fi
			return ;;
		esac
		cle reload ;;

	deploy) ## `cle deploy` - hook CLE into user's shell profile
		P=$HOME/.cle-$USER
		mkdir -p "$P"

		# Copy entire project structure
		cp "$CLE_RC" "$P/rc"
		for _SD in lib modules themes commands user; do
			[ -d "$CLE_RD/$_SD" ] && cp -r "$CLE_RD/$_SD" "$P/"
		done

		CLE_RC=$P/rc
		unset CLE_1
		I='# Command Live Environment'
		S=$HOME/.${SHELL##*/}rc
		grep -A1 "$I" "$S" 2>/dev/null && _clebold "CLE is already hooked in $S" && return 1
		_cleask "Do you want to add CLE to $S?" || return
		echo -e "\n$I\n[ -f $CLE_RC ] && . $CLE_RC\n" | tee -a "$S"
		cle reload ;;

	update) ## `cle update [branch]` - install fresh CLE version
		N=$CLE_D/rc.new
		curl -k "${CLE_SRC/Zodiac/${1:-Zodiac}}/clerc" >"$N"
		S=$(sed -n 's/^#\* version: //p' "$N")
		[ "$S" ] || { echo "Download error"; return 1; }
		echo "current: $CLE_VER"
		echo "new:     $S"
		I=$(diff "$CLE_RC" "$N") && { echo "No difference"; return 1; }
		_cleask "See diff?" && cat <<<"$I"
		_cleask "Install new version?" || return
		cp "$CLE_RC" "$CLE_D/rc.bk"
		chmod 755 "$N"
		mv -f "$N" "$CLE_RC"
		cle reload ;;

	reload) ## `cle reload [bash|zsh]` - reload CLE
		[[ "$1" =~ ^[bz] ]] && S=-$1
		[ "$S" ] && exec "$CLE_RC" $S
		unset CLE_EXE
		. "$CLE_RC"
		echo "CLE $CLE_VER" ;;

	mod)    ## `cle mod [new|list|help]` - module management
		_cle_mod "$@" ;;

	switch) ## `cle switch <profile>` - switch config profile (work/personal/etc)
		local PROF=$1
		[ -z "$PROF" ] && {
			echo "Available profiles:"
			for P in "$CLE_D"/profile-*; do
				[ -f "$P" ] && printf "  $_CL%s$_CN\n" "$(basename "$P" | sed 's/profile-//')"
			done
			echo ""
			echo "Usage: cle switch <profile>"
			echo "Create: cle switch save <name>"
			return
		}
		if [ "$PROF" = "save" ]; then
			local NAME=${2:?Usage: cle switch save <name>}
			cp "$CLE_CF" "$CLE_D/profile-$NAME"
			cp "$CLE_AL" "$CLE_D/profile-${NAME}.al" 2>/dev/null
			echo "Saved profile '$NAME'"
			return
		fi
		local PF="$CLE_D/profile-$PROF"
		[ -f "$PF" ] || { echo "Profile '$PROF' not found. Use: cle switch save <name>"; return 1; }
		cp "$PF" "$CLE_CF"
		[ -f "${PF}.al" ] && cp "${PF}.al" "$CLE_AL"
		cle reload
		echo "Switched to profile '$PROF'" ;;

	env)    ## `cle env` - inspect CLE variables
		_clevdump 'CLE.*' | awk -F= "{printf \"$_CL%-12s$_CN%s\n\",\$1,\$2}" ;;

	doctor) ## `cle doctor` - health check
		_cle_doctor ;;

	profile) ## `cle profile` - measure startup time of each component
		_cle_profile ;;

	rprompt) ## `cle rprompt [on|off]` - toggle right prompt (git, venv)
		case "$1" in
		on)
			export CLE_RPROMPT=1
			_cle_setup_rprompt
			echo "Right prompt enabled" ;;
		off|"")
			export CLE_RPROMPT=0
			_cle_setup_rprompt
			echo "Right prompt disabled" ;;
		esac ;;

	transient) ## `cle transient [on|off]` - toggle transient prompt (zsh only)
		case "$1" in
		on)
			export CLE_TRANSIENT=1
			_cle_setup_transient
			echo "Transient prompt enabled" ;;
		off|"")
			unset CLE_TRANSIENT
			echo "Transient prompt disabled (reload to fully reset)" ;;
		esac ;;

	audit)  ## `cle audit [on|off]` - toggle command audit logging
		case "$1" in
		on)
			export CLE_AUDIT=1
			echo "Audit logging enabled -> $CLE_AUDIT_LOG" ;;
		off|"")
			unset CLE_AUDIT
			echo "Audit logging disabled" ;;
		esac ;;

	debug)  ## `cle debug [on|off]` - toggle verbose tracing
		case "$1" in
		on)
			export CLE_DEBUG=1
			set -x
			echo "CLE debug mode ON (set -x)" ;;
		off|"")
			unset CLE_DEBUG
			set +x
			echo "CLE debug mode OFF" ;;
		esac ;;

	vi)     ## `cle vi` - edit CLE vimrc
		local _VF="$CLE_RD/user/vimrc"
		if [ -f "$_VF" ]; then
			vi "$_VF"
		else
			echo "No vimrc found at $_VF"
			_cleask "Create one?" && {
				mkdir -p "$CLE_RD/user"
				echo '" CLE vimrc - Add your settings here' > "$_VF"
				vi "$_VF"
			}
		fi ;;

	help|-h|--help) ## `cle help [fnc]` - show help
		P=$(ls "$CLE_D"/cle-* "$CLE_RD"/commands/cle-* 2>/dev/null)
		sed -En '/(^|.*[[:blank:]])##/s/.*##([[:blank:]]|$)(.*)/\2/p' \
			${CLE_EXE//:/ } $P | _clemdf | less -erFX ;;

	doc)    ## `cle doc` - show online documentation
		I=$(curl -sk "$CLE_SRC/doc/index.md")
		[[ $I =~ LICENSE ]] || { echo "Unable to get documentation"; return 1; }
		PS3="$_CL doc # $_CN"
		select N in $I; do
			[ "$N" ] && curl -sk "$CLE_SRC/doc/$N" | _clemdf | less -r
			break
		done ;;

	"")
		_clebnr
		sed -n 's/^#\*\(.*\)/\1/p' "$CLE_RC" ;;

	*)
		echo "Unknown command: cle $C"
		echo "Run 'cle help' for available commands"
		return 1 ;;
	esac
}

# --- Module Management ---
_cle_mod () {
	case "$1" in
	new)
		[ -z "$2" ] && { echo "Usage: cle mod new <name>"; return 1; }
		local MF="$CLE_RD/modules/mod-$2"
		[ -f "$MF" ] && { echo "Module mod-$2 already exists"; return 1; }
		cat > "$MF" <<-MODSKEL
		##
		## ** mod-$2: Description here **
		#* version: $(date +%F)

		## \`l$2\` - short description
		l$2 () {
		    echo "mod-$2: not yet implemented"
		}
		MODSKEL
		echo "Created module skeleton: $MF"
		echo "Edit with: vi $MF" ;;
	list)
		echo "$_CL=== CLE Modules ===$_CN"
		local _ML
		for _ML in "$CLE_RD"/modules/mod-* "$CLE_D"/mod-*; do
			[ -f "$_ML" ] || continue
			local _N=$(basename "$_ML")
			local _D=$(sed -n 's/^## \*\* \(.*\) \*\*/\1/p' "$_ML")
			printf "  $_Cg%-20s$_CN %s\n" "$_N" "$_D"
		done ;;
	help|"")
		echo "Usage: cle mod <command>"
		echo ""
		echo "Commands:"
		echo "  list       List installed modules with descriptions"
		echo "  new <name> Create a new module skeleton"
		echo "" ;;
	*)
		echo "Unknown: cle mod $1"
		echo "Run 'cle mod help' for usage" ;;
	esac
}

# --- Health Check ---
_cle_doctor () {
	echo "$_CL=== CLE Health Check ===$_CN"
	echo ""
	printf "  %-20s %s\n" "Version:" "$CLE_VER"
	printf "  %-20s %s\n" "Shell:" "$CLE_SH"
	printf "  %-20s %s\n" "RC File:" "$CLE_RC"
	printf "  %-20s %s\n" "CLE Dir:" "$CLE_D"
	printf "  %-20s %s\n" "CLE Lib:" "$CLE_LIB"
	printf "  %-20s %s\n" "Hostname:" "$CLE_FHN ($CLE_SHN)"
	printf "  %-20s %s\n" "User:" "$CLE_USER"
	echo ""

	echo "$_CU Files:$_Cu"
	for F in "$CLE_RC" "$CLE_AL" "$CLE_TW" "$CLE_CF" "$CLE_HIST"; do
		if [ -f "$F" ]; then
			printf "  $_Cg%-30s$_CN %s\n" "$F" "OK ($(wc -l <"$F") lines)"
		else
			printf "  $_Cy%-30s$_CN %s\n" "$F" "missing"
		fi
	done
	echo ""

	echo "$_CU Lib Modules:$_Cu"
	for F in "$CLE_LIB"/*.sh; do
		[ -f "$F" ] && printf "  $_Cg%-30s$_CN loaded\n" "$(basename "$F")"
	done
	echo ""

	echo "$_CU Modules:$_Cu"
	local MC=0
	for F in "$CLE_D"/mod-* "$CLE_RD"/modules/mod-*; do
		if [ -f "$F" ]; then
			printf "  $_Cg%-30s$_CN active\n" "$(basename "$F")"
			((MC++))
		fi
	done
	[ $MC -eq 0 ] && echo "  (none)"
	echo ""

	echo "$_CU Tools:$_Cu"
	for T in fzf tmux screen git starship eza bat delta python3 curl jq; do
		if command -v "$T" >/dev/null 2>&1; then
			printf "  $_Cg%-12s$_CN installed\n" "$T"
		else
			printf "  $_Cy%-12s$_CN not found\n" "$T"
		fi
	done
	echo ""

	echo "$_CU Config:$_Cu"
	[ -f "$CLE_RD/user/vimrc" ] && printf "  $_Cg%-20s$_CN active\n" "vimrc" || printf "  $_Cy%-20s$_CN missing\n" "vimrc"
	[ -n "$VIMINIT" ] && printf "  $_Cg%-20s$_CN set\n" "VIMINIT" || printf "  $_Cy%-20s$_CN not set\n" "VIMINIT"
	printf "  %-20s %s\n" "Modules:" "$MC"
}

# --- Startup Profiler ---
# Portable millisecond timer: python3 fallback for macOS (no date +%s%N)
_cle_ms () {
	if [ "$ZSH_NAME" ] && (( ${+EPOCHREALTIME} )); then
		echo "${EPOCHREALTIME/./}"
	else
		python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || echo $((SECONDS * 1000))
	fi
}

_cle_profile () {
	echo "$_CL=== CLE Startup Profile ===$_CN"
	echo ""

	local _T0 _T1 _DUR _TOTAL=0

	echo "$_CU Library files:$_Cu"
	for _f in init utils colors prompt history aliases navigation sessions cle; do
		local _FP="$CLE_LIB/${_f}.sh"
		[ -f "$_FP" ] || continue
		_T0=$(_cle_ms)
		. "$_FP" 2>/dev/null
		_T1=$(_cle_ms)
		_DUR=$((_T1 - _T0))
		_TOTAL=$((_TOTAL + _DUR))
		printf "  %-20s %d ms\n" "${_f}.sh" "$_DUR"
	done
	printf "\n  %-20s %d ms\n\n" "TOTAL lib:" "$_TOTAL"

	echo "$_CU Modules:$_Cu"
	for M in "$CLE_D"/mod-* "$CLE_RD"/modules/mod-*; do
		[ -f "$M" ] || continue
		local _MN=$(basename "$M")
		_T0=$(_cle_ms)
		. "$M" 2>/dev/null
		_T1=$(_cle_ms)
		_DUR=$((_T1 - _T0))
		printf "  %-20s %d ms\n" "$_MN" "$_DUR"
	done
	echo ""

	echo "$_CU Aliases:$_Cu"
	local _AC=$(builtin alias | wc -l | tr -d ' ')
	printf "  %-20s %s aliases loaded\n" "$CLE_AL" "$_AC"
	echo ""

	echo "$_CU History:$_Cu"
	local _HC=$(wc -l < "$CLE_HIST" 2>/dev/null | tr -d ' ')
	printf "  %-20s %s entries\n" "$CLE_HIST" "${_HC:-0}"
}

# --- Completions ---
_cle_setup_completions () {
	_clecomp () {
		local A=(color p0 p1 p2 p3 cf mod env update reload doc help doctor profile debug deploy switch starship rprompt transient audit ed vi)
		local C
		COMPREPLY=()
		case $3 in
		p0) COMPREPLY="'$CLE_P0'" ;;
		p1) COMPREPLY="'$CLE_P1'" ;;
		p2) COMPREPLY="'$CLE_P2'" ;;
		p3) COMPREPLY="'$CLE_P3'" ;;
		esac
		[ "$3" != "$1" ] && return
		for C in "${A[@]}"; do
			[[ $C =~ ^$2 ]] && COMPREPLY+=("$C")
		done
	}

	if [ $BASH ]; then
		local _N=/usr/share/bash-completion
		_clexe "$_N/bash_completion"
		_clexe "$_N/completions/ssh"
		typeset -f _known_hosts >/dev/null 2>&1 && complete -F _known_hosts lssh
		typeset -f _ssh >/dev/null 2>&1 && complete -F _ssh lssh
		typeset -f _comp_cmd_ssh >/dev/null 2>&1 && complete -F _comp_cmd_ssh lssh
		complete -F _clecomp cle
	else
		autoload -Uz compinit && compinit -u 2>/dev/null
		autoload -Uz bashcompinit && bashcompinit 2>/dev/null
		compdef lssh=ssh 2>/dev/null
		compdef '_arguments "1:command:(color p0 p1 p2 p3 cf mod env update reload doc help doctor deploy starship profile debug rprompt transient audit switch ed vi)"' cle 2>/dev/null
	fi
}
