## lib/init.sh - Variable initialization
# Sets up all CLE paths, identity, and directory structure

_cle_init_vars () {
	_H=$HOME
	[ -w "$_H" ] || _H=$_T
	[ -r "$HOME" ] || HOME=$_H
	[ "$PWD" = "$_T" ] && cd

	CLE_D=$_H/$(sed 's:/.*/\(\..*\)/.*:\1:' <<<"$CLE_RC")
	mkdir -m 755 -p "$CLE_D"

	CLE_CF=$CLE_D/cf-$CLE_FHN
	CLE_AL=$CLE_D/al
	CLE_HIST=$_H/.clehistory

	local _N
	_N=$(sed 's:.*/rc1*::' <<<"$CLE_RC")
	CLE_WS=${_N/-/}
	CLE_TW=$CLE_RD/tw${_N}
	CLE_ENV=$CLE_RD/env${_N}
	CLE_TTY=$(tty | tr -d '/dev')
	PROMPT_DIRTRIM=3

	unset _H
}

_cle_init_host () {
	CLE_FHN=$HOSTNAME
	local _N
	_N=$(hostname)
	[ ${#CLE_FHN} -lt ${#_N} ] && CLE_FHN=$_N
	CLE_IP=${CLE_IP:-$(cut -d' ' -f3 <<<"$SSH_CONNECTION")}
	CLE_SHN=$(eval sed "${CLE_SRE:-'s:\.[^.]*\.[^.]*$::'}" <<<"$CLE_FHN")

	_N=$(sed -n 's;.*cle-\(.*\)/.*;\1;p' <<<"$CLE_RC")
	export CLE_USER=${CLE_USER:-${_N:-$(whoami)}}
}

_cle_init_dirs () {
	mkdir -m 755 -p "$CLE_D"
}

_cle_load_config () {
	[ -r "$CLE_CF" ] && read _N <"$CLE_CF" || _N=v2
	[[ $_N =~ (v2|Zodiac) ]] || {
		local _O=$CLE_D/cf-old
		mv -f "$CLE_CF" "$_O" 2>/dev/null
		local _R="s!^#.*!# $CLE_VER!"
		if [ "$CLE_WS" ]; then
			_R=$_R";/^CLE_P/d"
		else
			_R=$_R";s/^CLE_P\(.\)='\(.*\)'/CLE_PB\1='\2 '/"
			_R=$_R";s/%/^/g;s/\^c/^C/g;s/\^e/^E/g"
		fi
		[ -f "$_O" ] && sed -e "$_R" <"$_O" >"$CLE_CF"
		rm -f "$CLE_D/cle-mod" 2>/dev/null
	}
	_clexe "$CLE_CF"
}
