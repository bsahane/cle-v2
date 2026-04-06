## lib/navigation.sh - Directory navigation enhancements

## `..`  - go up one level
## `...` - go up two levels
## `-`   - cd to previous directory
- () { cd - >/dev/null; _clevdump OLDPWD; }
.. () { cd ..; }
... () { cd ../..; }

## `mkcd <dir>` - create directory and cd into it
mkcd () { mkdir -p "$1" && cd "$1"; }

## `take <dir>` - mkcd alias (Oh-My-Zsh compat)
take () { mkcd "$@"; }

## `bd <parent>` - jump back to a parent directory by name
bd () {
	local OLD=$PWD NEW
	[ -z "$1" ] && { echo "Usage: bd <parent_dir_name>"; return 1; }
	NEW="${PWD%/$1/*}/$1"
	[ "$NEW" = "$OLD" ] && { echo "'$1' not found in path"; return 1; }
	cd "$NEW"
}

## `up [n]` - go up n directories (default: 1)
up () {
	local D=""
	local N=${1:-1}
	while [ "$N" -gt 0 ]; do
		D="../$D"
		N=$((N - 1))
	done
	cd "$D"
}

## `xx`  - bookmark current directory
## `cx`  - cd to bookmarked directory
xx () { _XX=$PWD; echo "path bookmark: $_XX"; _clerh @ "$PWD" "xx"; }
cx () { cd "$_XX"; }

## `bm [name] [path]` - named bookmark manager
##   bm             - list all bookmarks
##   bm name        - set bookmark to current directory
##   bm name /path  - set bookmark to specified path
##   bm -d name     - delete bookmark
##   bm -g name     - go to bookmark (same as 'go' command)
bm () {
	local BM_FILE=$CLE_D/bookmarks
	case "$1" in
	"")
		if [ -f "$BM_FILE" ]; then
			while IFS='=' read -r name path; do
				[ -n "$name" ] && printf "$_CL%-15s$_CN %s\n" "$name" "$path"
			done < "$BM_FILE"
		else
			echo "No bookmarks set. Use: bm <name> [path]"
		fi ;;
	-d)
		if [ -f "$BM_FILE" ]; then
			grep -v "^${2}=" "$BM_FILE" > "$BM_FILE.tmp" && mv "$BM_FILE.tmp" "$BM_FILE"
			echo "Removed bookmark '$2'"
		else
			echo "No bookmarks file"
		fi ;;
	-g)
		go "$2" ;;
	*)
		local P=${2:-$PWD}
		[ -f "$BM_FILE" ] && grep -v "^$1=" "$BM_FILE" > "$BM_FILE.tmp" && mv "$BM_FILE.tmp" "$BM_FILE"
		echo "$1=$P" >> "$BM_FILE"
		echo "Bookmark '$1' -> $P" ;;
	esac
}

## `go <name>` - jump to named bookmark
go () {
	local BM_FILE=$CLE_D/bookmarks
	local P
	P=$(grep "^$1=" "$BM_FILE" 2>/dev/null | cut -d= -f2-)
	[ -n "$P" ] && cd "$P" || echo "Bookmark '$1' not found. Use: bm"
}

## `fcd [dir]` - fuzzy cd using fzf (if available)
fcd () {
	if command -v fzf >/dev/null 2>&1; then
		local dir
		dir=$(find "${1:-.}" -type d -not -path '*/\.*' 2>/dev/null | fzf +m) && cd "$dir"
	else
		echo "fzf not installed. Install with: brew install fzf (macOS) or apt install fzf (Linux)"
	fi
}
