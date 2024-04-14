# android-tools-AppImage
Unofficial AppImage of Android Platform Tools (adb, fastboot, etc). 

Turns the released binaries from here into an AppImage: [platform-tools](https://developer.android.com/tools/releases/platform-tools)

You can also run the android-tools-appimage.sh script in your machine to make the AppImage.

If you are missing android udev rules you can usually get them from your distro repos or use the flag `--getudev` with the AppImage to install them. 

It is possible that this appimage may fail to work with appimagelauncher, since appimagelauncher is pretty much dead I recommend this alternative: https://github.com/ivan-hc/AM

This appimage works without `fuse2` as it can use `fuse3` instead.
