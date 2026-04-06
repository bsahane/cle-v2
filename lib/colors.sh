## lib/colors.sh - Terminal color management

# Build the complete color table from terminal capabilities
_cletable () {
	_C_=$TERM
	_CN=$(tput sgr0)
	_CL=$(tput bold)
	_CU=$(tput smul); _Cu=$(tput rmul)
	_CV=$(tput rev)
	_CI=$(tput sitm); _Ci=$(tput ritm)
	_CD=$(tput dim)

	_Ck=$_CN$(tput setaf 0)
	_Cr=$_CN$(tput setaf 1)
	_Cg=$_CN$(tput setaf 2)
	_Cy=$_CN$(tput setaf 3)
	_Cb=$_CN$(tput setaf 4)
	_Cm=$_CN$(tput setaf 5)
	_Cc=$_CN$(tput setaf 6)
	_Cw=$_CN$(tput setaf 7)

	case $(tput colors) in
	8)
		_CK=$_Ck$_CL; _CR=$_Cr$_CL; _CG=$_Cg$_CL; _CY=$_Cy$_CL
		_CB=$_Cb$_CL; _CM=$_Cm$_CL; _CC=$_Cc$_CL; _CW=$_Cw$_CL ;;
	*)
		_CK=$_CN$(tput setaf 8)$_CL;  _CR=$_CN$(tput setaf 9)$_CL
		_CG=$_CN$(tput setaf 10)$_CL; _CY=$_CN$(tput setaf 11)$_CL
		_CB=$_CN$(tput setaf 12)$_CL; _CM=$_CN$(tput setaf 13)$_CL
		_CC=$_CN$(tput setaf 14)$_CL; _CW=$_CN$(tput setaf 15)$_CL ;;
	esac
	_Ce=$_CR$_CL$_CV
}

# Parse and apply a color scheme string (3-5 char code or named preset)
_cleclr () {
	local C I CI E
	case "$1" in
	red)       C=RrR ;;
	green)     C=GgG ;;
	yellow)    C=YyY ;;
	blue)      C=BbB ;;
	cyan)      C=CcC ;;
	magenta)   C=MmM ;;
	grey|gray) C=wNW ;;
	tricolora) C=RBW ;;
	marley)    C=RYG ;;
	*)         C=$1 ;;
	esac

	[ ${#C} = 3 ] && C=D${C}L || C=${C}L
	for I in {0..4}; do
		eval "CI=\$_C${C:$I:1}"
		if [[ -z "$CI" && ! ${C:$I:1} =~ [ID] ]]; then
			echo "Wrong color code '${C:$I:1}' in $1" && CI=$_CN
			E=1
		fi
		eval "_C$I=\$CI"
	done
	[ ${C:0:1} = D ] && _C0=$_C1$_CD

	if [ "$E" ]; then
		echo "Choose predefined scheme:$_CL"
		declare -f _cleclr | sed -n 's/^[ \t]*(*\(\<[a-z |]*\)).*/ \1/p' | tr -d '\n|'
		printf "\n${_CN}Create your own 3-5 letter combo using rgbcmykw/RGBCMYKW\n"
		printf "E.g.:$_CL cle color rgB\n"
		_cleclr gray
		return 1
	else
		CLE_CLR=${C:0:5}
	fi
}
