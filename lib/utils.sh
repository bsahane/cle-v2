## lib/utils.sh - Shared utility functions

# Print bold text
_clebold () {
	printf "$_CL$*$_CN\n"
}

# Interactive yes/no prompt
_cleask () (
	local PR="$_CL$* (y/N) $_CN"
	[ "$ZSH_NAME" ] && read -ks "?$PR" || read -n 1 -s -p "$PR"
	echo ${REPLY:=n}
	[ "$REPLY" = "y" ]
)

# Render markdown-like formatting for terminal output
_clemdf () {
	sed -e "s/^###\(.*\)/$_CL\1$_CN/" \
	    -e "s/^##\( *\)\(.*\)/\1$_CU$_CL\2$_CN/" \
	    -e "s/^#\( *\)\(.*\)/\1$_CL$_CV \2 $_CN/" \
	    -e "s/\*\*\(.*\)\*\*/$_CL\1$_CN/" \
	    -e "s/\<_\(.*\)_\>/$_CU\1$_Cu/g" \
	    -e "s/\`\`\`/$_CD~~~~~~~~~~~~~~~~~$_CN/" \
	    -e "s/\`\([^\`]*\)\`/$_Cg\1$_CN/g"
}

# Dump shell variables matching a pattern
_clevdump () (
	typeset 2>/dev/null | awk '/.* \(\)/{exit} /(^'"$1"')=/{gsub(/\\C-\[/,"\\E");print}'
)

# CLE banner
_clebnr () {
cat <<EOT

$_CC   ___| |     ____| $_CN Command Live Environment activated
$_CB  |     |     __|   $_CN ...bit of life to the command line
$_Cb  |     |     |     $_CN Learn more:$_CL cle help$_CN and$_CL cle doc$_CN
$_Cb$_CD \____|_____|_____| $_CN Uncover the magic:$_CL less $CLE_RC$_CN

EOT
}

# Desktop notification for long-running commands
# Enable with: CLE_NOTIFY_THRESHOLD=30 (seconds)
_cle_notify () {
	local CMD=$1 DUR=$2 EXIT=$3
	local STATUS="completed"
	[ "$EXIT" != 0 ] && STATUS="FAILED (exit $EXIT)"
	local MSG="$CMD $STATUS (${DUR}s)"
	case $OSTYPE in
	darwin*)
		osascript -e "display notification \"$MSG\" with title \"CLE\" sound name \"Glass\"" 2>/dev/null ;;
	linux*)
		notify-send -t 5000 "CLE" "$MSG" 2>/dev/null ;;
	esac
}

# Easter egg
_cle_r () {
	[ "$1" != h ] && return
	printf "\n$_Cr     ,==~~-~w^, \n    /#=-.,#####\\ \n .,!. ##########!\n((###,. \`\"#######;."
	printf "\n &######\`..#####;^###)\n$_CW   (@@$_Cr^#############\"\n$_CW"
	printf "    \\@@@\\__,-~-__,\n     \`&@@@@@69@@/\n        ^&@@@@&*\n$_CN\n"
}
