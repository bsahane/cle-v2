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
