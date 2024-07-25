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
UDEVNOTICE="If you get errors it might be because of missing android udev rules, use --getudev to install them"
ARGS="$(echo "$@" | cut -f2- -d ' ')"
export PATH="$CURRENTDIR:$PATH"
if [ "$1" = "adb" ]; then
	"$CURRENTDIR"/adb $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "etc1tool" ]; then
	"$CURRENTDIR"/etc1tool $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "fastboot" ]; then
	"$CURRENTDIR"/fastboot $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "make_f2fs" ]; then
	"$CURRENTDIR"/make_f2fs $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "make_f2fs_casefold" ]; then
	"$CURRENTDIR"/make_f2fs_casefold $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "mke2fs" ]; then
	"$CURRENTDIR"/mke2fs $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "sqlite3" ]; then
	"$CURRENTDIR"/sqlite3 $ARGS || echo "$UDEVNOTICE"
	elif [ "$1" = "--getudev" ]; then
	if cat /etc/udev/rules.d/*droid.rules > /dev/null; then
		echo "udev rules already installed"
		echo "Errors persisting with installed udev rules may be due to specific phone missing from the rules or insufficient permissions on the phone"
	else
		UDEVREPO="https://github.com/M0Rf30/android-udev-rules.git"	
		git clone "$UDEVREPO"
		cd android-udev-rules || exit 1
		chmod a+x ./install.sh
		echo "udev rules installer from $UDEVREPO"
		sudo ./install.sh
		cd .. && cat /etc/udev/rules.d/*droid.rules > /dev/null && rm -rf "./android-udev-rules"
	fi
else
	echo "Error: No command specified, try \"./*tools.AppImage adb shell\" for example"
	echo "You can also use aliases or wrapper scripts to not write ./*tools.AppImage every time"
	echo "$UDEVNOTICE"
	echo "Falling back to example adb shell:"
	read -p "Do you wan to run adb shell? (y/n): " yn
	if echo "$yn" | grep -i '^y' >/dev/null 2>&1; then
		"$CURRENTDIR"/adb shell
	fi
fi
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
