#!/bin/sh
##
## CLE v2 Installer
## Deploys CLE to ~/.cle-$USER and hooks into shell profile
## Compatible with bash, zsh, and POSIX sh
##

set -e

CLE_USER=$(whoami)
SRC_DIR=$(cd "$(dirname "$0")"; pwd)
DEST_DIR="$HOME/.cle-$CLE_USER"
SHELL_RC="$HOME/.$(basename "$SHELL")rc"

echo "=== CLE v2 Installer ==="
echo ""
echo "  Source:      $SRC_DIR"
echo "  Destination: $DEST_DIR"
echo "  Shell RC:    $SHELL_RC"
echo ""

# Check if already installed
if [ -d "$DEST_DIR" ] && [ -f "$DEST_DIR/rc" ]; then
	echo "CLE already installed at $DEST_DIR"
	printf "Overwrite? (y/N) "
	read REPLY
	case "$REPLY" in [Yy]*) ;; *) echo "Aborted."; exit 1 ;; esac
	cp -r "$DEST_DIR" "${DEST_DIR}.bk.$(date +%s)"
fi

# Create destination
mkdir -p "$DEST_DIR"

# Copy project structure
cp "$SRC_DIR/rc" "$DEST_DIR/"
chmod 755 "$DEST_DIR/rc"

for DIR in lib modules themes commands; do
	if [ -d "$SRC_DIR/$DIR" ]; then
		cp -r "$SRC_DIR/$DIR" "$DEST_DIR/"
	fi
done

# Copy user files only if they don't already exist
for UF in tw al; do
	if [ ! -f "$DEST_DIR/$UF" ] && [ -f "$SRC_DIR/user/$UF" ]; then
		cp "$SRC_DIR/user/$UF" "$DEST_DIR/"
	fi
done

echo "Files deployed to $DEST_DIR"

# Hook into shell profile
HOOK='# Command Live Environment'
CLE_RC="$DEST_DIR/rc"

if grep -q "$HOOK" "$SHELL_RC" 2>/dev/null; then
	echo "CLE is already hooked in $SHELL_RC"
else
	printf "Add CLE to $SHELL_RC? (y/N) "
	read REPLY
	case "$REPLY" in
	[Yy]*)
		printf "\n$HOOK\n[ -f $CLE_RC ] && . $CLE_RC\n" >> "$SHELL_RC"
		echo "Added CLE hook to $SHELL_RC" ;;
	esac
fi

echo ""
echo "Installation complete!"
echo "Start a new shell or run:  source $CLE_RC"
