## lib/prompt.sh - Prompt engine

# Translate CLE prompt escapes to shell-native escapes
_clesc () (
	EXTESC="
	 -e 's/\^i/\$CLE_IP/g'
	 -e 's/\^h/\$CLE_SHN/g'
	 -e 's/\^H/\$CLE_FHN/g'
	 -e 's/\^U/\$CLE_USER/g'
	 -e 's/\^g/\$(_clegitwb)/g'
	 -e 's/\^K/\$(_cle_prompt_k8s)/g'
	 -e 's/\^V/\$(_cle_prompt_venv)/g'
	 -e 's/\^A/\$(_cle_prompt_sshagent)/g'
	 -e 's/\^D/\$(_cle_prompt_container)/g'
	 -e 's/\^?/\$_EC/g'
	 -e 's/\^[E]/\\$_PE\$_CE\\$_Pe\[\$_EC\]\\$_PE\$_CN\$_C0\\$_Pe/g'
	 -e 's/\^[C]\(.\)/\\$_PE\\\$_C\1\\$_Pe/g'
	 -e 's/\^v\([[:alnum:]_]*\)/\1=\$\1/g'
	 -e 's/\^\^/\^/g'
	"
	if [ "$ZSH_NAME" ]; then
		SHESC="-e 's/\\\\n/\$_PN/g'
		 -e 's/\\^[$%#]/%#/g'
		 -e 's/\\\\d/%D{%a %b %d}/g'
		 -e 's/\\\\D/%D/g'
		 -e 's/\\\\h/%m/g'
		 -e 's/\\\\H/%M/g'
		 -e 's/\\\\j/%j/g'
		 -e 's/\\\\l/%l/g'
		 -e 's/\\\\s/zsh/g'
		 -e 's/\\\\t/%*/g'
		 -e 's/\\\\T/%D{%r}/g'
		 -e 's/\\\\@/%@/g'
		 -e 's/\\\\A/%T/g'
		 -e 's/\\\\u/%n/g'
		 -e 's/\\\\w/%$PROMPT_DIRTRIM~/g'
		 -e 's/\\\\W/%1~/g'
		 -e 's/\\\\!/%!/g'
		 -e 's/\\\\#/%i/g'
		 -e 's/\\\\\[/%{/g'
		 -e 's/\\\\\]/%}/g'
		 -e 's/\\\\\\\\/\\\\/g'
		"
	else
		SHESC="-e 's/\^[$%#]/\\\\\$/g'"
	fi
	SUBS=$(tr -d '\n\t' <<<"$SHESC$EXTESC")
	eval sed "$SUBS" <<<"$*"
)

# Override default prompt strings with configured values
_clepcp () {
	local I
	for I in 0 1 2 3 T; do
		eval "CLE_P$I=\${CLE_PB$I:-\$CLE_P$I}"
		[ "$ZSH_NAME" ] && eval "CLE_P$I=\${CLE_PZ$I:-\$CLE_P$I}"
		[ "$1" ] && unset CLE_P{B,Z}$I
	done
}

# Assemble the final PS1/PS2 from prompt parts
_cleps () {
	[ "$CLE_PT" ] && PS1="$_PE\${_CT}$(_clesc "$CLE_PT")\${_Ct}$_Pe" || PS1=''
	PS1=$PS1$(_clesc "^C0$CLE_P0^C1$CLE_P1^C2$CLE_P2^C3$CLE_P3^CN^C4")
	PS2=$(_clesc "^C3>>> ^CN^C4")
}

# Set default prompt strings and auto-detect color scheme
_cledefp () {
	CLE_P0='^E \t '
	CLE_P1='\u '
	CLE_P2='^h '
	CLE_P3='\w ^$ '
	CLE_PT='\u@^H'
	case "$USER-${CLE_WS#$CLE_FHN}" in
	root-)  _DC=red ;;
	*-)     _DC=marley ;;
	root-*) _DC=RbB ;;
	*-*)    _DC=blue ;;
	esac
}

# Save configuration to host-specific file
_clesave () (
	echo "# $CLE_VER"
	_clevdump "CLE_CLR|CLE_PB.|CLE_PZ."
) >"$CLE_CF"

# Detect current git branch (walks up directory tree)
# Uses cached result if directory hasn't changed
_clegitwb () (
	while [ "$PWD" != / ]; do
		[ -d .git ] && { git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null; return; }
		cd ..
	done
	return 1
)

# Prompt segments for additional context (^K = k8s, ^V = venv, ^A = ssh-agent)
_cle_prompt_k8s () {
	command -v kubectl >/dev/null 2>&1 || return
	local ctx ns
	ctx=$(kubectl config current-context 2>/dev/null) || return
	ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
	[ -n "$ns" -a "$ns" != "default" ] && echo "$ctx/$ns" || echo "$ctx"
}

_cle_prompt_venv () {
	[ -n "$VIRTUAL_ENV" ] && basename "$VIRTUAL_ENV"
}

_cle_prompt_sshagent () {
	local keys
	keys=$(ssh-add -l 2>/dev/null | grep -c '^[0-9]')
	[ "$keys" -gt 0 ] 2>/dev/null && echo "${keys}k"
}

_cle_prompt_container () {
	[ -f /.dockerenv ] && echo "docker" && return
	[ -f /run/.containerenv ] && echo "podman" && return
	[ -d /run/secrets/kubernetes.io ] && echo "k8s-pod" && return
}

# Right prompt - shows git branch, venv, duration on the right side
# zsh: uses native RPROMPT. bash: draws with cursor positioning in precmd
_cle_rprompt_text () {
	local parts=""
	local gb
	gb=$(_clegitwb)
	[ -n "$gb" ] && parts="${parts} ${gb}"
	local venv
	venv=$(_cle_prompt_venv)
	[ -n "$venv" ] && parts="${parts} ($venv)"
	[ -n "$parts" ] && echo "$parts "
}

_cle_setup_rprompt () {
	if [ "${CLE_RPROMPT:-0}" = 0 ]; then
		unset RPROMPT 2>/dev/null
		return
	fi
	if [ "$ZSH_NAME" ]; then
		RPROMPT='%{$_Cb%}$(_cle_rprompt_text)%{$_CN%}'
	fi
}

# Transient prompt: replaces previous prompt with a minimal one after execution
# Enable with: CLE_TRANSIENT=1
_cle_setup_transient () {
	[ "${CLE_TRANSIENT:-0}" = 0 ] && return
	[ -z "$ZSH_NAME" ] && return
	_cle_transient_accept () {
		zle -I
		local lines
		lines=${PROMPT//[^$'\n']}
		local nl=${#lines}
		if [ $nl -gt 0 ]; then
			printf '\e[%dA\e[K' "$nl"
			printf '\r%s\n' "${_Cb}$ ${_CN}${BUFFER}"
			printf '\e[%dB' "$((nl - 1))"
		fi
		zle .accept-line
	}
	zle -N accept-line _cle_transient_accept
}
