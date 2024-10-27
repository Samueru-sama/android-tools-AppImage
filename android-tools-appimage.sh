#!/bin/sh

export ARCH=x86_64
APP=android-tools-appimage
APPDIR="$APP".AppDir
SITE="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
ICON="https://developer.android.com/static/images/brand/Android_Robot.png"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
SHARUN="https://bin.ajam.dev/$(uname -m)/sharun"
LIB4BIN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# CREATE DIRECTORIES AND DOWNLOAD THE ARCHIVE
[ -n "$APP" ] || exit 1
mkdir -p ./"$APP"/"$APPDIR"/shared && cd ./"$APP"/"$APPDIR" || exit 1
wget "$SITE" && unzip -q *.zip && rm -f ./*.zip || exit 1
mv ./platform-tools ./shared/bin || exit 1

# DESKTOP & ICON
cat >> ./Android-$APP.desktop << 'EOF'
[Desktop Entry]
Name=Android-platform-tools
Type=Application
Icon=Android
Exec="sh -ic ' android-tools "";"" \\$SHELL'"
Categories=Utility;
Terminal=true
EOF
wget "$ICON" -O ./Android.png && ln -s ./Android.png ./.DirIcon

# BUNDLE ALL DEPENDENCIES
wget "$SHARUN" -O ./sharun || exit 1
wget "$LIB4BIN" -O ./lib4bin || exit 1
chmod +x ./sharun ./lib4bin

HARD_LINKS=1 ./lib4bin ./shared/bin/* && rm -f ./lib4bin || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
UDEVNOTICE='No android udev rules detected, use "--getudev" to install'
UDEVREPO="https://github.com/M0Rf30/android-udev-rules.git"
cat /etc/udev/rules.d/*droid.rules >/dev/null 2>&1 && UDEVNOTICE=""
BIN="${ARGV0#./}"
unset ARGV0
export PATH="$CURRENTDIR/bin:$PATH"

_get_udev_rules() {
	if cat /etc/udev/rules.d/*droid.rules >/dev/null 2>&1; then
		echo "ERROR: udev rules are already installed!"
		echo "Errors persisting with installed udev rules may be due to missing"
		echo "udev rules for device or lack of permissions from device"
		exit 1
	fi
	if ! command -v git >/dev/null 2>&1; then
		echo "ERROR: you need git to use this function"
		exit 1
	fi
	if command -v sudo >/dev/null 2>&1; then
		SUDOCMD="sudo"
	elif command -v doas >/dev/null 2>&1; then
		SUDOCMD="doas"
	else
		echo "ERROR: You need sudo or doas to use this function"
		exit 1
	fi
	printf '%s' "udev rules installer from $UDEVREPO, run installer? (y/N): "
	read -r yn
	if echo "$yn" | grep -i '^y' >/dev/null 2>&1; then
		tmpudev=".udev_rules_tmp.dir"
		git clone "$UDEVREPO" "$tmpudev" && cd "$tmpudev" || exit 1
		chmod +x ./install.sh && "$SUDOCMD" ./install.sh
		cat /etc/udev/rules.d/*droid.rules >/dev/null 2>&1 || exit 1
		cd .. && rm -rf "$tmpudev" || exit 1
		echo "udev rules installed successfully!"
	else
		echo "Aborting..."
		exit 1
	fi
}

_get_symlinks() {
	BINDIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
	links="$(find "$CURRENTDIR"/shared/bin -maxdepth 1 -exec file {} \; \
		| awk -F":" '/ELF/ {print $1}' | xargs -I {} basename {} 2>/dev/null)"
	echo ""
	echo "This function will make wrapper symlinks in $BINDIR"
	echo "that will point to $APPIMAGE with the names:"
	echo "$links" | tr ' ' '\n'
	echo ""
	echo "Make sure there are not existing files $BINDIR with those names"
	printf '\n%s' "Proceed with the symlink creation? (Y/n): "
	read -r yn
	if echo "$yn" | grep -i '^n' >/dev/null 2>&1; then
		echo "Aborting..."
		exit 1
	fi
	mkdir -p "$BINDIR" || exit 1
	for link in $links; do
			ln -s "$APPIMAGE" "$BINDIR/$link" 2>/dev/null \
				&& echo "\"$link\" symlink successfully created in \"$BINDIR\""
	done
}

# logic
if [ -n "$BIN" ] && [ -e "$CURRENTDIR/bin/$BIN" ]; then
	"$CURRENTDIR/bin/$BIN" "$@" || echo "$UDEVNOTICE"
elif [ -n "$1" ] && [ -e "$CURRENTDIR/bin/$1" ]; then
	option="$1"
	shift
	"$CURRENTDIR/bin/$option" "$@" || echo "$UDEVNOTICE"
else
	case "$1" in
	'--getudev')
		_get_udev_rules
		;;
	'--getlinks')
		_get_symlinks
		;;
	*)
		echo ""
		echo "USAGE: \"${APPIMAGE##*/} [ARGUMENT]\""
		echo "EXAMPLE: \"${APPIMAGE##*/} adb shell\" to enter adb shell"
		echo ""
		echo "You can also make a symlink to $APPIMAGE named adb"
		echo "and run the symlink to enter adb without typing ${APPIMAGE##*/}"
		echo ""
		echo 'use "--getlinks" if you want to make the symlinks automatically'
		echo ""
		exit 1
		;;
	esac
fi
EOF
chmod a+x ./AppRun
export VERSION="$(awk -F"=" '/vision/ {print $2}' ./shared/bin/source.properties)"

# Do the thing!
cd .. && wget -q "$APPIMAGETOOL" -O appimagetool && chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 ./"$APPDIR" || exit 1
[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf "$APP" || exit 1
echo "All Done!"
