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
echo "[Desktop Entry]
Name=Android-platform-tools
Type=Application
Icon=Android
TryExec=android-tools-appimage
Exec='sh -ic "android-tools-appimage adb shell; exec bash"'
Categories=Utility;
Terminal=true" >> "./Android-$APP.desktop"

# GET ICON
wget https://developer.android.com/static/images/brand/Android_Robot.png -O ./Android.png 2> /dev/null 
ln -s ./Android.png ./.DirIcon

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/bash
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
UDEVNOTICE=$(echo "If you get errors it might be because you don't have the android udev rules for your device" )
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
