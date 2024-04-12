#!/bin/sh

APP=android-tools-appimage
SITE="https://dl.google.com/android/repository"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p "./$APP/tmp" && cd "./$APP/tmp" || exit

# DOWNLOAD THE ARCHIVE
wget "$SITE/platform-tools-latest-linux.zip" && unzip -qq ./*.zip
cd ..
mkdir "./$APP.AppDir" && mv --backup=t ./tmp/*/* ./$APP.AppDir
cd ./$APP.AppDir || exit

# DESKTOP ENTRY
cat >> ./Android-$APP.desktop << 'EOF'
[Desktop Entry]
Name=Android-platform-tools
Type=Application
Icon=Android
TryExec=android-tools-appimage
Exec="sh -ic 'android-tools-appimage adb shell"";"" exec bash'"
Categories=Utility;
Terminal=true
EOF

# GET ICON
wget https://developer.android.com/static/images/brand/Android_Robot.png -O ./Android.png 2> /dev/null 
ln -s ./Android.png ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/bash
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
UDEVNOTICE=$(echo "If you get errors it might be because of missing android udev rules, use --getudev to install them")
if [ "$1" = "adb" ]; then
	"$CURRENTDIR"/adb "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "etc1tool" ]; then
	"$CURRENTDIR"/etc1tool "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "fastboot" ]; then
	"$CURRENTDIR"/fastboot "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "make_f2fs" ]; then
	"$CURRENTDIR"/make_f2fs "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "make_f2fs_casefold" ]; then
	"$CURRENTDIR"/make_f2fs_casefold "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "mke2fs" ]; then
	"$CURRENTDIR"/mke2fs "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "sqlite3" ]; then
	"$CURRENTDIR"/sqlite3 "${@:2}" || echo "$UDEVNOTICE"
	elif [ "$1" = "--getudev" ]; then
	if cat /etc/udev/rules.d/*droid.rules > /dev/null; then
		echo "udev rules already installed"
		echo “Errors persisting with installed udev rules may be due to specific phone missing from the rules or insufficient permissions on the phone”
	else
		UDEVREPO=https://github.com/M0Rf30/android-udev-rules.git	
		git clone $UDEVREPO
		cd android-udev-rules
		chmod a+x ./install.sh
		echo "udev rules installer from $UDEVREPO"
		sudo ./install.sh
		cd .. && cat /etc/udev/rules.d/*droid.rules > /dev/null && rm -rf "./android-udev-rules"
	fi
else
	echo "Error: No command specified, try \"./*tools.AppImage adb shell\" for example"
	echo "You can also use aliases or wrapper scripts to not write ./*tools.AppImage every time"
	echo "$UDEVNOTICE"
fi
EOF
chmod a+x ./AppRun

# MAKE APPIMAGE
APPVERSION=$(cat source.properties | grep vision | awk -F = '{print $NF; exit}')
cd ..
wget -q $(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | grep -v zsync | grep -i continuous | grep -i appimagetool | grep -i x86_64 | grep browser_download_url | cut -d '"' -f 4 | head -1) -O appimagetool
chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP.AppDir && 
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }
mv ./*AppImage ./"$APPVERSION"-"android-tools.AppImage"
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf "./$APP"
echo "All Done!"
