#!/bin/sh

APP=android-tools-appimage
APPDIR="$APP".AppDir
SITE="https://dl.google.com/android/repository"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p "./$APP/tmp" && cd "./$APP/tmp" || exit 1

# DOWNLOAD THE ARCHIVE
wget "$SITE/platform-tools-latest-linux.zip" && unzip -qq ./*.zip && cd .. \
&& mkdir -p "./$APP.AppDir/usr/bin" && mv --backup=t ./tmp/*/* "./$APP.AppDir/usr/bin" \
&& cd ./"$APPDIR" || exit 1

# DESKTOP ENTRY
cat >> ./Android-$APP.desktop << 'EOF'
[Desktop Entry]
Name=Android-platform-tools
Type=Application
Icon=Android
Exec="sh -ic ' android-tools "";"" \\$SHELL'"
Categories=Utility;
Terminal=true
EOF

# GET ICON
wget https://developer.android.com/static/images/brand/Android_Robot.png -O ./Android.png 2> /dev/null
ln -s ./Android.png ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"/usr/bin
UDEVNOTICE='No android udev rules detected, use "--getude" to install'
UDEVREPO="https://github.com/M0Rf30/android-udev-rules.git"
export PATH="$CURRENTDIR:$PATH"

_get_udev_rules() {
	if cat /etc/udev/rules.d/*droid.rules >/dev/null 2>&1; then
		echo "udev rules already installed!"
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
	links="adb etc1tool fastboot make_f2fs make_f2fs_casefold mke2fs sqlite3"
	echo ""
	echo "This function will make wrapper symlinks in $BINDIR"
	echo "that will point to $APPIMAGE"
	echo ""
	echo "with the names: \"$links\""
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
case $ARGV0 in
	'adb'|'etc1tool'|'fastboot'|'make_f2fs'|\
	'make_f2fs_casefold'|'mke2fs'|'sqlite3')
		"$CURRENTDIR/$ARGV0" "$@" || echo "$UDEVNOTICE"
		;;
	*)
		case $1 in
		'adb'|'etc1tool'|'fastboot'|'make_f2fs'|\
		'make_f2fs_casefold'|'mke2fs'|'sqlite3')
			option="$1"
			shift
			"$CURRENTDIR/$option" "$@" || echo "$UDEVNOTICE"
			;;
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
	;;
esac
EOF
chmod a+x ./AppRun
APPVERSION=$(awk -F = '/Revision/ {print $2; exit}' ./usr/bin/source.properties)

# MAKE APPIMAGE
cd ..
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/[()",{}]/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')
wget -q "$APPIMAGETOOL" -O appimagetool
chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR" || { echo "appimagetool failed to make the appimage"; exit 1; }
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf "./$APP"
echo "All Done!"
